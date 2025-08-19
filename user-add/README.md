# 🧩 RGAP 사용자 등록 자동화 스크립트

이 저장소는 **RGAP(Remote GPU Access Platform)** 환경에서 신규 사용자를 손쉽게 추가할 수 있도록 도와주는 셸 스크립트를 포함하고 있습니다.
본 스크립트는 다음을 자동화합니다:

* **Dex** (Kubeflow의 인증 시스템)에 정적 사용자 추가
* 해당 사용자를 위한 **Kubeflow Profile** 네임스페이스 생성

---

## 📜 스크립트 개요

스크립트는 다음 절차를 자동으로 수행합니다:

1. **필수 도구 확인 및 설치**

   * `yq`: YAML 처리 도구 (설치되어 있지 않으면 자동 설치)
   * `htpasswd`: bcrypt 해시 생성을 위한 도구 (`apache2-utils` 패키지에 포함)

2. **사용자 정보 입력**

   * 사용자 이름, 이메일, 비밀번호를 입력 받음
   * 비밀번호에 대한 **bcrypt 해시값**과 **UUID** 생성

3. **Dex 설정(ConfigMap) 수정**

   * 현재 Dex 설정을 가져와 임시 YAML 파일에 저장
   * 입력된 이메일이 이미 존재하는지 확인
   * 새 사용자 정보를 `staticPasswords` 항목에 추가
   * YAML 유효성 검사 및 변경사항 적용
   * Dex 디플로이먼트 재시작

4. **Kubeflow Profile 생성**

   * 사용자 이름을 소문자로 변환하여 네임스페이스로 사용
   * 해당 이메일을 owner로 하는 Profile YAML 생성
   * Profile 리소스를 클러스터에 적용

---

## ⚙️ 사전 요구 사항

* 다음 구성 요소가 준비되어 있어야 합니다:

  * **Kubeflow가 설치된 Kubernetes 클러스터**
  * **Dex가 `auth` 네임스페이스에서 운영 중**
* CLI 도구:

  * `kubectl`
  * `htpasswd` (예: `sudo apt install apache2-utils`)
  * `yq` (스크립트 내에서 자동 설치 가능)

---

## 🚀 사용 방법

```bash
chmod +x RGAP_user_add.sh
./RGAP_user_add.sh
```

실행 후 다음 정보를 입력해야 합니다:

* **Username**: 로그인 시 사용할 사용자 이름 (Profile 이름에도 사용됨)
* **Email**: 사용자 ID로 사용될 이메일 주소
* **Password**: 로그인용 비밀번호

모든 과정이 성공적으로 완료되면:

✅ Dex 사용자 등록
✅ Kubeflow Profile 네임스페이스 자동 생성

---

## 🛑 예외 처리 및 에러 방지

* 동일 이메일이 이미 Dex 설정에 존재할 경우: ❌ 등록 중단
* 동일 이름의 Profile이 이미 존재할 경우: ❌ 등록 중단
* Dex ConfigMap YAML이 유효하지 않은 경우: ❌ 적용 중단 후 내용 출력
* Profile 생성 실패 시: ❌ YAML 파일 보존 후 사용자 수동 확인 요청

---

## 📂 생성되는 파일

* `dex_config_temp.yaml`: Dex 설정 임시 저장 파일 (적용 후 삭제됨)
* `user-profile-<username>.yaml`: Kubeflow Profile 정의 파일 (성공 시 삭제됨)

---

## 📧 문의

스크립트 사용 중 문제가 발생하면 이슈를 등록하거나 플랫폼 관리자에게 문의해 주세요.

---
