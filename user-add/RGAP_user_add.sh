#!/bin/bash

# Dex + Kubeflow Profile 사용자 추가 스크립트

# yq 설치 확인
if ! command -v yq &> /dev/null; then
    echo "yq is not installed. Installing yq..."
    sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
    sudo chmod +x /usr/bin/yq
fi

# htpasswd 설치 확인
if ! command -v htpasswd &> /dev/null; then
    echo "htpasswd is not installed. Please install apache2-utils (e.g., 'apt-get install apache2-utils')."
    exit 1
fi

# 사용자 정보 입력
read -p "Enter username (for login): " USERNAME
read -p "Enter email (used as userID): " EMAIL
read -s -p "Enter password: " PASSWORD
echo

# 비밀번호 해시 생성
HASH=$(echo "$PASSWORD" | htpasswd -nB -C 10 -i "$USERNAME" | cut -d: -f2)
UUID=$(uuidgen)

echo "Generated bcrypt hash: $HASH"
echo "Generated UUID: $UUID"

# Dex ConfigMap 수정
CONFIGMAP_FILE="dex_config_temp.yaml"
kubectl get configmap dex -n auth -o yaml > "$CONFIGMAP_FILE"

# 사용자 중복 확인
duplicated_user=$(yq eval ".data.\"config.yaml\" | fromyaml | .staticPasswords[] | select(.email == \"$EMAIL\")" "$CONFIGMAP_FILE")
if [ -n "$duplicated_user" ]; then
    echo "User with email $EMAIL already exists in Dex ConfigMap. Aborting."
    exit 1
fi

yq eval ".data.\"config.yaml\" |= (fromyaml | .staticPasswords += [{\"email\": \"$EMAIL\", \"hash\": \"$HASH\", \"username\": \"$USERNAME\", \"userID\": \"$UUID\"}] | toyaml)" -i "$CONFIGMAP_FILE"

# YAML 검증 및 적용
if ! kubectl apply -f "$CONFIGMAP_FILE" --dry-run=client -o yaml > /dev/null 2>&1; then
    echo "Invalid YAML in $CONFIGMAP_FILE"
    cat "$CONFIGMAP_FILE"
    exit 1
fi

kubectl apply -f "$CONFIGMAP_FILE" && echo "Dex ConfigMap updated."
rm "$CONFIGMAP_FILE"

# Dex Pod 재시작
kubectl rollout restart deploy dex -n auth
echo "Dex Pod restarted."

# Kubeflow Profile 생성
PROFILE_NAME=$(echo "$USERNAME" | tr '[:upper:]' '[:lower:]')  # namespace 이름: 소문자
PROFILE_FILE="user-profile-$PROFILE_NAME.yaml"

# 프로파일 중복 확인
if kubectl get profile "$PROFILE_NAME" &> /dev/null; then
    echo "Profile $PROFILE_NAME already exists. Aborting."
    exit 1
fi

cat <<EOF > "$PROFILE_FILE"
apiVersion: kubeflow.org/v1
kind: Profile
metadata:
  name: $PROFILE_NAME
spec:
  owner:
    kind: User
    name: $EMAIL
EOF

echo "Generated Profile YAML:"
cat "$PROFILE_FILE"

# Profile 생성
kubectl apply -f "$PROFILE_FILE"
if [ $? -eq 0 ]; then
    echo "Kubeflow Profile '$PROFILE_NAME' created successfully."
    rm "$PROFILE_FILE"
else
    echo "Failed to create Profile. You may want to inspect $PROFILE_FILE."
    exit 1
fi

echo "User '$USERNAME' has been added and profile namespace '$PROFILE_NAME' has been created."
