# AMD Kria KV260 EDF Linux

AMD Kria KV260 보드용 EDF(Embedded Development Framework) Linux 빌드 및 배포 환경을 구성하는 저장소입니다. Yocto 기반 외부 소스의 버전을 고정하고, 프로젝트 전용 설정과 자동화 절차를 단계적으로 관리합니다.

현재는 `rel-v2026.1` 계열의 외부 저장소 18개를 고정한 초기 구성입니다. KV260 빌드 설정, 배포 자동화, 보드 부팅 검증은 아직 완료하지 않았습니다.

## 프로젝트 구조

```text
kv260_edf/
├── README.md
├── .gitignore
├── init_edf.sh             # repo 초기화 및 고정 manifest로 소스 동기화
├── manifests/
│   └── edf-pinned.xml       # 외부 저장소 경로와 커밋 고정
├── sources/                # repo sync로 받는 외부 Yocto 레이어
├── edf-init-build-env      # 소스 동기화 시 복사되는 환경 초기화 스크립트
└── build/                  # 환경 초기화 후 생성되는 빌드 디렉터리
```

`build/`는 초기 저장소에 포함되어 있지 않으며, 아래 초기화 명령으로 생성합니다.

## 고정 manifest의 역할

[`manifests/edf-pinned.xml`](manifests/edf-pinned.xml)은 `repo` 도구가 사용할 저장소 목록입니다. `repo`는 여러 Git 저장소를 하나의 작업 디렉터리에서 동기화합니다.

- `remote`: 외부 저장소를 가져올 주소입니다. 현재는 `https://github.com/Xilinx`입니다.
- `project`: 저장소 이름과 `sources/` 아래 배치할 경로를 지정합니다.
- `revision`: 사용할 정확한 Git 커밋을 고정합니다.
- `upstream`: 해당 커밋이 속한 브랜치 정보를 제공합니다.
- `copyfile`: `meta-amd-edf`의 초기화 스크립트를 루트의 `edf-init-build-env`로 복사합니다.

브랜치가 업데이트되어도 이 manifest로 동기화하면 지정된 소스 커밋을 다시 가져올 수 있습니다. 다만 로컬 소스 수정, 빌드 설정, 호스트 환경까지 저장하는 파일은 아니므로, 이것만으로 동일한 빌드 결과 전체가 보장되지는 않습니다.

## 빌드 준비

Linux 빌드 호스트에서 Bash, Git, `repo`, Yocto 빌드 의존성을 준비합니다. 충분한 디스크 공간과 소스 다운로드를 위한 네트워크 연결이 필요합니다. 호스트 준비에 관한 상세 절차는 동기화 후 `sources/meta-amd-edf/README.build.md`를 참고합니다.

### 1. repo 설치 및 PATH 설정

`init_edf.sh`를 실행하기 전에 `repo`를 별도로 설치해야 합니다. EDF의 `sources/meta-amd-edf/README.build.md` 안내에 따라 공식 배포 스크립트를 다운로드하고, 설치 디렉터리를 `PATH`에 추가합니다. EDF 문서는 패키지 관리자로 설치한 `repo`가 오래된 버전일 수 있으므로, 해당 방식으로 설치했다면 먼저 제거하도록 안내합니다.

```bash
mkdir -p "$HOME/bin"
curl -fL https://storage.googleapis.com/git-repo-downloads/repo -o "$HOME/bin/repo"
chmod a+x "$HOME/bin/repo"
export PATH="$HOME/bin:$PATH"

# 사용할 repo 경로 및 실행 확인
command -v repo
repo --help
```

새 Bash 터미널에서도 사용할 수 있도록 `~/.bashrc`에 아래 줄을 한 번 추가합니다. 위의 `export`는 현재 터미널에만 적용됩니다.

```bash
export PATH="$HOME/bin:$PATH"
```

### 2. 외부 소스 동기화

이 저장소를 clone한 디렉터리의 루트에서 실행합니다.

```bash
bash ./init_edf.sh
```

`init_edf.sh`는 AMD manifest 저장소로 `repo` 작업 공간을 초기화하고, `manifests/edf-pinned.xml`을 적용한 뒤 `repo sync -j4`로 외부 소스를 동기화합니다. `repo` 설치 및 `PATH` 설정은 스크립트에 포함되어 있지 않으므로 앞 단계를 먼저 완료해야 합니다.

`.repo/manifests/edf-pinned.xml`은 도구가 읽기 위한 복사본입니다. Git으로 관리할 원본은 `manifests/edf-pinned.xml`이며, 원본을 변경한 경우 `init_edf.sh`를 다시 실행하여 적용합니다.

동기화가 완료되면 `sources/`의 외부 저장소들과 루트의 `edf-init-build-env`가 준비됩니다.

### 3. 빌드 환경 초기화

프로젝트 루트에서 Bash로 실행합니다.

```bash
unset TEMPLATECONF
source ./edf-init-build-env build
```

초기화 스크립트는 EDF 기본 템플릿으로 `build/conf/local.conf`와 `build/conf/bblayers.conf`를 생성하고, 현재 디렉터리를 `build/`로 이동합니다. 새 터미널에서 작업할 때도 프로젝트 루트에서 같은 명령으로 환경을 불러옵니다.

### 4. KV260 설정 및 이미지 빌드

기본 템플릿의 `MACHINE`은 `qemuarm64`이므로 KV260 대상으로 변경해야 합니다. `build/conf/local.conf`에서 기존 `MACHINE` 설정을 다음으로 바꾸고, `DISTRO`도 확인합니다.

```bitbake
MACHINE = "k26-smk-kv-sdt"
DISTRO = "amd-edf"
```

환경이 초기화된 `build/` 디렉터리에서 실행하는 빌드 예시입니다.

```bash
bitbake edf-linux-disk-image-kria
```

위 머신과 이미지 레시피는 현재 체크아웃된 `meta-kria` 및 `meta-amd-edf` 소스에서 확인했습니다. 이 프로젝트에서 실제 빌드 성공과 KV260 부팅까지 검증한 절차는 아닙니다.

기본 `TMPDIR` 설정을 사용하는 경우 산출물 위치는 다음과 같습니다.

```text
build/tmp/deploy/images/k26-smk-kv-sdt/
```

SD 카드 기록과 보드 부트 펌웨어 설정을 포함한 실제 배포 절차는 보드 검증 후 추가합니다.

