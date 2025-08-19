
# Dex 사용자 추가 스크립트

이 스크립트(`dex-user-add.sh`)는 Kubeflow 환경에서 Dex 인증 시스템에 새로운 사용자를 추가하는 과정을 자동화합니다. Dex는 OpenID Connect(OIDC) 기반의 인증 서비스로, Kubeflow에서 사용자 인증을 담당합니다. 이 스크립트를 사용하면 명령줄에서 간단한 입력만으로 새 사용자를 등록하고, Dex 설정을 업데이트할 수 있습니다.

## 스크립트 역할

이 스크립트는 다음과 같은 작업을 순차적으로 수행합니다:

1. **사용자 정보 입력**: 사용자 이름, 이메일, 비밀번호를 입력받습니다.
2. **비밀번호 해시 생성**: 입력한 비밀번호를 bcrypt 해시로 변환합니다.
3. **UUID 생성**: 사용자에게 고유한 UUID를 생성합니다.
4. **ConfigMap 수정**: Dex의 ConfigMap(`dex` in `auth` 네임스페이스)을 업데이트하여 새 사용자 정보를 추가합니다.
5. **Dex Pod 재시작**: 변경된 설정을 적용하기 위해 Dex Pod를 재시작합니다.

## 사용 방법

### 사전 요구 사항

- **Kubernetes 클러스터**: Kubeflow가 설치된 클러스터에 접근할 수 있어야 합니다.
- **`kubectl`**: 클러스터에 명령을 실행할 수 있는 권한이 필요합니다.
- **`htpasswd`**: 비밀번호 해시를 생성하기 위해 `apache2-utils` 패키지가 설치되어 있어야 합니다.
  ```bash
  sudo apt-get install apache2-utils  # Ubuntu/Debian
  sudo yum install httpd-tools       # CentOS/RHEL
  ```
- **`yq`**: YAML 파일을 안전하게 수정하기 위해 필요합니다. 스크립트가 자동으로 설치하지만, 수동 설치 방법도 아래에 제공됩니다.

### 스크립트 실행 단계

1. **스크립트 다운로드**:
   ```bash
   git clone https://github.com/WoogiBoogi1129/Multi-Cluster-ML-Workload.git
   cd Multi-Cluster-ML-Workload/dex
   ```

2. **실행 권한 부여**:
   ```bash
   chmod +x dex-user-add.sh
   ```

3. **스크립트 실행**:
   ```bash
   ./dex-user-add.sh
   ```

4. **사용자 정보 입력**:
   - **사용자 이름**: Dex에서 사용할 사용자 이름(예: `newuser`).
   - **이메일**: 사용자의 이메일 주소(예: `newuser@example.com`).
   - **비밀번호**: 사용자 비밀번호(입력 시 화면에 표시되지 않음).

5. **자동화된 작업**:
   - 스크립트가 비밀번호 해시와 UUID를 생성합니다.
   - Dex ConfigMap을 수정하여 새 사용자 정보를 추가합니다.
   - Dex Pod를 재시작하여 변경 사항을 적용합니다.

6. **결과 확인**:
   - 스크립트가 성공적으로 실행되면 다음과 같은 메시지가 출력됩니다:
     ```
     ConfigMap 'dex' updated successfully.
     Dex Pod restarted successfully.
     User 'newuser' added to Dex successfully!
     ```

## 스크립트 동작 원리

1. **사용자 정보 입력**:
   - 사용자 이름, 이메일, 비밀번호를 순차적으로 입력받습니다.

2. **비밀번호 해시 생성**:
   - `htpasswd` 명령어를 사용하여 bcrypt 해시를 생성합니다:
     ```bash
     HASH=$(echo "$PASSWORD" | htpasswd -nB -C 10 -i "$USERNAME" | cut -d: -f2)
     ```

3. **UUID 생성**:
   - `uuidgen` 명령어로 고유한 UUID를 생성합니다.

4. **ConfigMap 수정**:
   - `kubectl get configmap dex -n auth -o yaml`로 현재 ConfigMap을 다운로드합니다.
   - `yq`를 사용하여 `staticPasswords` 배열에 새 사용자 정보를 추가합니다:
     ```bash
     yq eval ".data.\"config.yaml\" |= (fromyaml | .staticPasswords += [{\"email\": \"$EMAIL\", \"hash\": \"$HASH\", \"username\": \"$USERNAME\", \"userID\": \"$UUID\"}] | toyaml)" -i "$CONFIGMAP_FILE"
     ```

5. **YAML 유효성 검사**:
   - `kubectl apply --dry-run=client`로 수정된 ConfigMap의 유효성을 검사합니다.

6. **ConfigMap 적용 및 Pod 재시작**:
   - `kubectl apply -f "$CONFIGMAP_FILE"`로 ConfigMap을 업데이트합니다.
   - `kubectl delete pod -l app=dex -n auth`로 Dex Pod를 재시작합니다.

## 주의 사항

- **권한 확인**:
  - `kubectl` 명령어가 실행 가능한 권한이 필요합니다. 특히 ConfigMap 수정 및 Pod 삭제 권한이 있어야 합니다.
- **ConfigMap 백업**:
  - 스크립트 실행 전, ConfigMap을 백업해 두는 것이 좋습니다:
    ```bash
    kubectl get configmap dex -n auth -o yaml > dex_backup.yaml
    ```
- **Pod 재시작**:
  - Dex Pod가 여러 개일 경우, 모두 재시작되므로 서비스 중단 여부를 확인하세요.
- **YAML 오류**:
  - YAML 형식이 잘못되면 스크립트가 중단됩니다. 오류 발생 시 `dex_config_temp.yaml` 파일을 확인하세요.

## 문제 해결

- **`htpasswd` 설치 오류**:
  - `htpasswd`가 없으면 스크립트가 중단됩니다. 위의 사전 요구 사항에 따라 설치 후 재시도하세요.
- **`yq` 설치 문제**:
  - 스크립트가 자동으로 `yq`를 설치하지만, 실패할 경우 수동 설치:
    ```bash
    sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
    sudo chmod +x /usr/bin/yq
    ```
- **ConfigMap 수정 실패**:
  - `dex_config_temp.yaml` 파일을 열어 YAML 형식이 올바른지 확인하세요.
