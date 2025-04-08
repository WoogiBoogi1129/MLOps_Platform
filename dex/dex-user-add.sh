#!/bin/bash

# Dex 사용자 추가 스크립트

# yq 설치 확인
if ! command -v yq &> /dev/null; then
    echo "yq is not installed. Installing yq..."
    sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
    sudo chmod +x /usr/bin/yq
fi

# 0. 사용자 이름 입력
read -p "Enter username: " USERNAME

# 1. 이메일 입력
read -p "Enter email: " EMAIL

# 2. 비밀번호 입력 및 해시 생성
read -s -p "Enter password: " PASSWORD
echo # 줄바꿈
if ! command -v htpasswd &> /dev/null; then
    echo "htpasswd is not installed. Please install apache2-utils (e.g., 'apt-get install apache2-utils')."
    exit 1
fi
HASH=$(echo "$PASSWORD" | htpasswd -nB -C 10 -i "$USERNAME" | cut -d: -f2)
echo "Generated bcrypt hash: $HASH"

# 3. UUID 생성
UUID=$(uuidgen)
echo "Generated UUID: $UUID"

# 4. ConfigMap dex -n auth 수정
CONFIGMAP_FILE="dex_config_temp.yaml"
kubectl get configmap dex -n auth -o yaml > "$CONFIGMAP_FILE"

# 4.1 staticPasswords에 사용자 정보 추가
# yq를 사용하여 staticPasswords 배열에 새 사용자 추가
yq eval ".data.\"config.yaml\" |= (fromyaml | .staticPasswords += [{\"email\": \"$EMAIL\", \"hash\": \"$HASH\", \"username\": \"$USERNAME\", \"userID\": \"$UUID\"}] | toyaml)" -i "$CONFIGMAP_FILE"

# YAML 유효성 검사
if ! kubectl apply -f "$CONFIGMAP_FILE" --dry-run=client -o yaml > /dev/null 2>&1; then
    echo "Invalid YAML format in $CONFIGMAP_FILE. Check the file for errors."
    cat "$CONFIGMAP_FILE"
    exit 1
fi

# ConfigMap 적용
kubectl apply -f "$CONFIGMAP_FILE"
if [ $? -eq 0 ]; then
    echo "ConfigMap 'dex' updated successfully."
else
    echo "Failed to update ConfigMap 'dex'."
    cat "$CONFIGMAP_FILE" # 오류 확인용 파일 출력
    exit 1
fi

# 5. Dex Pod 재시작
kubectl delete pod -l app=dex -n auth
if [ $? -eq 0 ]; then
    echo "Dex Pod restarted successfully."
    rm "$CONFIGMAP_FILE" # 성공 시 임시 파일 삭제
else
    echo "Failed to restart Dex Pod."
    rm "$CONFIGMAP_FILE"
    exit 1
fi

echo "User '$USERNAME' added to Dex successfully!"
