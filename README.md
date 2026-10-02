# AMD Kria KV260 EDF Linux

AMD Kria KV260 보드용 EDF(Embedded Development Framework) Linux 빌드 및 배포 환경을 구성하는 저장소입니다. Yocto 기반 외부 소스의 버전을 고정하고, 프로젝트 전용 설정과 자동화 절차를 단계적으로 관리합니다.


## 프로젝트 구조

```text
kv260_edf/
├── README.md
├── .gitignore
├── Dockerfile              # AMD EDF 기반 개발 이미지
├── docker-compose.yaml     # 대화형 개발 및 일회성 빌드 서비스
├── init_edf.sh             # repo 초기화 및 고정 manifest로 소스 동기화
├── manifests/
│   └── edf-pinned.xml      # 외부 저장소 경로와 커밋 고정
├── sources/                # repo sync로 받는 외부 Yocto 레이어
├── edf-init-build-env      # 소스 동기화 시 복사되는 환경 초기화 스크립트
└── build/                  # 환경 초기화 후 생성되는 빌드 디렉터리
```

`build/`는 초기 저장소에 포함되어 있지 않으며, 아래 초기화 명령으로 생성합니다.

[`manifests/edf-pinned.xml`](manifests/edf-pinned.xml)은 `repo` 도구가 사용할 저장소 목록입니다. `repo`는 여러 Git 저장소를 하나의 작업 디렉터리에서 동기화합니다.
브랜치가 업데이트되어도 이 manifest로 동기화하면 지정된 소스 커밋을 다시 가져올 수 있습니다. 다만 로컬 소스 수정, 빌드 설정, 호스트 환경까지 저장하는 파일은 아니므로, 이것만으로 동일한 빌드 결과 전체가 보장되지는 않습니다.

## 빌드 준비 (공통)

Host PC 개발과 Docker 개발 모두 먼저 호스트에서 소스를 준비합니다. Bash, Git, `repo`, 충분한 디스크 공간과 소스 다운로드를 위한 네트워크 연결이 필요합니다.

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

이후 사용할 환경에 따라 **Host PC에서 개발** 또는 **Docker를 통한 개발** 중 하나를 진행합니다.

## Host PC에서 개발

호스트에서 직접 빌드 도구를 실행하는 방식입니다. Linux 호스트에 Yocto 빌드 의존성을 설치합니다. 상세 준비 절차는 동기화된 `sources/meta-amd-edf/README.build.md`를 참고합니다.

### 1. 빌드 환경 초기화

프로젝트 루트에서 Bash로 실행합니다.

```bash
source ./edf-init-build-env build
```

초기화 스크립트는 EDF 기본 템플릿으로 `build/conf/local.conf`와 `build/conf/bblayers.conf`를 생성하고, 현재 디렉터리를 `build/`로 이동합니다. 새 터미널에서 작업할 때도 프로젝트 루트에서 같은 명령으로 환경을 불러옵니다.

### 2. KV260 설정 및 이미지 빌드

기본 템플릿의 `MACHINE`은 `qemuarm64`이므로 KV260 대상으로 변경해야 합니다. `build/conf/local.conf`에서 기존 `MACHINE` 설정을 다음으로 바꾸고, `DISTRO`도 확인합니다.

```bitbake
MACHINE = "zynqmp-kv260-sdt-full"
DISTRO = "amd-edf"
```

환경이 초기화된 `build/` 디렉터리에서 실행하는 빌드 예시입니다.

```bash
bitbake kv260-image
```

`kv260-image`는 `meta-kv260` 레이어의 [recipes-core/images/kv260-image.bb](sources/meta-kv260/recipes-core/images/kv260-image.bb)에 정의한 커스텀 이미지입니다. EDF의 `edf-linux-disk-image.bb`를 기반으로 하며, PL 비트스트림과 디바이스 트리 오버레이를 제공하는 `kv260-pl-firmware`, PL 로딩 도구를 제공하는 `fpga-manager-script`를 추가로 포함합니다. 해당 레이어가 `build/conf/bblayers.conf`에 등록되어 있어야 합니다.

## Docker를 통한 개발

공통 빌드 준비를 마친 뒤 호스트에 Docker Engine과 Docker Compose 플러그인(`docker compose`)을 준비합니다. [Dockerfile](Dockerfile)은 `xilinx/edf:ubuntu2204-26.06` 이미지를 사용하며, 빌드 도구는 컨테이너 안에서 실행합니다. 아래 절차는 Host PC 개발 섹션을 수행하지 않고 진행할 수 있습니다.

### 서비스 구성

[docker-compose.yaml](docker-compose.yaml)은 다음 두 서비스를 제공합니다.

| 서비스 | 용도 | 실행 방식 |
| --- | --- | --- |
| `edf-linux_dev` | Bash에 접속해 환경을 초기화하고, 레시피 수정 후 반복 빌드하는 대화형 개발 환경 | `docker compose up -d --build`로 시작하고 `docker compose exec edf-linux_dev bash`로 접속합니다. 빌드는 접속 후 직접 실행합니다. |
| `edf-linux_build` | 준비된 설정으로 지정한 타깃을 빌드하고 종료하는 일회성 빌드 | `BITBAKE_TARGET=kv260-image docker compose run --rm --build edf-linux_build`로 실행합니다. Compose 기본 타깃은 `edf-linux-disk-image-kria`이므로 커스텀 이미지를 명시합니다. |

`edf-linux_dev`는 프로필 없이 기본 실행됩니다. `edf-linux_build`는 선택적으로 실행할 서비스를 묶는 `build` 프로필에 속하므로 일반 `docker compose up`으로 시작되지 않습니다. `run` 명령에 서비스 이름을 직접 지정하면 별도 프로필 옵션 없이 실행됩니다.

두 서비스는 같은 이미지와 호스트의 `sources/`, `build/`를 공유합니다. 같은 빌드 디렉터리에서 두 서비스의 BitBake를 동시에 실행하지 마세요.

### 1. 개발 컨테이너 접속

**호스트의 프로젝트 루트**에서 실행합니다.

```bash
mkdir -p build
docker compose up -d --build
docker compose exec edf-linux_dev bash
```

컨테이너의 작업 디렉터리는 `/home/amd-edf/edf`입니다. 현재 Compose 설정은 호스트의 `sources/`와 `build/`만 같은 이름의 하위 디렉터리에 연결합니다. 루트의 `init_edf.sh`, `manifests/`, `edf-init-build-env`는 공유하지 않으므로 소스 동기화는 호스트에서 수행합니다.

### 2. 컨테이너 안에서 환경 초기화 및 개발

**컨테이너의 Bash**에서 다음 명령으로 EDF 템플릿을 지정하고 빌드 환경을 불러옵니다. 새로 접속할 때마다 실행합니다.

```bash
cd "$PROJECT_ROOT"
source ./sources/poky/oe-init-build-env build
```

초기화 후 현재 디렉터리는 `/home/amd-edf/edf/build`가 됩니다. 처음 실행하면 `conf/`에 설정 파일이 생성되며, 기존 설정 파일이 있으면 유지합니다. 호스트 편집기로 `build/conf/local.conf`를 열어 기존 `MACHINE`을 KV260 대상으로 변경하고 `DISTRO`를 확인합니다.

```bitbake
MACHINE = "zynqmp-kv260-sdt-full"
DISTRO = "amd-edf"
```

`sources/meta-kv260`이 `build/conf/bblayers.conf`에 등록되어 있어야 합니다. 호스트에서 `sources/` 아래 레이어나 레시피를 수정하면 컨테이너에도 바로 반영됩니다. 환경을 초기화한 컨테이너의 `build/` 디렉터리에서 빌드합니다.

```bash
bitbake kv260-image
```

기본 `TMPDIR`을 사용하면 호스트의 `build/tmp/deploy/images/zynqmp-kv260-sdt-full/`에서 산출물을 확인할 수 있습니다. 설정에 호스트 전용 절대 경로가 있다면 컨테이너에서도 접근 가능한 경로인지 확인합니다. 공유 디렉터리의 쓰기 권한 오류가 발생하면 호스트 디렉터리 소유권과 컨테이너 사용자(`id`)의 UID/GID를 확인합니다.

### 3. 일회성 빌드

위 초기화와 KV260 설정을 마친 뒤, **호스트의 프로젝트 루트**에서 실행합니다.

```bash
BITBAKE_TARGET=kv260-image docker compose run --rm --build edf-linux_build
```

`edf-linux_build`는 빌드 환경을 불러와 BitBake를 실행합니다. `--rm`으로 실행한 컨테이너는 종료 후 삭제되지만, 호스트의 설정, 빌드 캐시, 산출물은 유지됩니다.

다른 타깃을 빌드하려면 환경 변수로 지정합니다.

```bash
BITBAKE_TARGET=core-image-minimal docker compose run --rm --build edf-linux_build
```

### 4. 작업 종료 및 재접속

컨테이너 Bash에서 `exit`로 빠져나온 뒤, 호스트의 프로젝트 루트에서 컨테이너를 종료합니다.

```bash
docker compose down
```

공유한 `sources/`와 `build/`는 호스트에 남습니다. 다시 작업하려면 `docker compose up -d`와 `docker compose exec edf-linux_dev bash`를 실행한 뒤, 위의 컨테이너 환경 초기화 명령을 다시 실행합니다.

Docker 안내는 현재 저장소의 설정에 맞춘 절차이며, 컨테이너에서 전체 이미지 빌드와 보드 부팅까지 검증한 상태는 아닙니다.

## 보드 배포

SD 카드 기록과 보드 부트 펌웨어 설정을 포함한 실제 배포 절차는 보드 검증 후 추가합니다.
