#!/bin/bash

# Dex + Kubeflow Profile 사용자 삭제 스크립트

# yq 설치 확인
if ! command -v yq &> /dev/null; then
    echo "yq is not installed. Installing yq..."
    sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
    sudo chmod +x /usr/bin/yq
fi

# 사용자 정보 입력
read -p "Enter username (for login): " USERNAME
read -p "Enter email (used as userID): " EMAIL

# Dex ConfigMap 수정
CONFIGMAP_FILE="dex_config_temp.yaml"
kubectl get configmap dex -n auth -o yaml > "$CONFIGMAP_FILE"

# 사용자 존재 확인
user_entry=$(yq eval ".data.\"config.yaml\" | fromyaml | .staticPasswords[] | select(.email == \"$EMAIL\")" "$CONFIGMAP_FILE")
if [ -z "$user_entry" ]; then
    echo "User with email $EMAIL not found in Dex ConfigMap. Aborting."
    rm "$CONFIGMAP_FILE"
    exit 1
fi

# 사용자 삭제
yq eval ".data.\"config.yaml\" |= (fromyaml | .staticPasswords |= map(select(.email != \"$EMAIL\")) | toYaml)" -i "$CONFIGMAP_FILE"

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

# Kubeflow Profile 삭제
PROFILE_NAME=$(echo "$USERNAME" | tr '[:upper:]' '[:lower:]')  # namespace 이름: 소문자

if kubectl get profile "$PROFILE_NAME" &> /dev/null; then
    kubectl delete profile "$PROFILE_NAME"
    echo "Kubeflow Profile '$PROFILE_NAME' deleted."
else
    echo "Profile $PROFILE_NAME not found. Skipping profile deletion."
fi

echo "User '$USERNAME' has been removed."
