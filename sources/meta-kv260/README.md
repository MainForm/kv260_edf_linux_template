# meta-kv260 EDF Yocto Layer Template

AMD Kria KV260 보드를 위한 EDF(Embedded Development Framework) Yocto 레이어입니다. SDT(System Device Tree)로부터 생성한 머신 BSP 설정과 PL 펌웨어, 커스텀 이미지 레시피를 함께 관리합니다. AMD Vivado Tool를 사용하여 디자인한 PL을 EDF Linux에 적용하기 위한 레이어입니다.


## 개발 환경

AMD EDF(Embedded Developement Framewoark) 2026.01 버전을 기반으로 개발되었습니다.

## 파일 구조

```text
meta-kv260/
├── conf/
│   ├── layer.conf
|   ├── kv260-settings.inc
|   |   -------------------- gen-machine-conf로 생성된 파일들 ---------------------
│   ├── machine/                    # 생성된 머신 설정과 include 파일
│   ├── multiconfig/                # 생성된 FSBL, PMU 펌웨어 빌드 설정
│   └── dts/                        # 생성된 Device Tree 파일
│       └── zynqmp-kv260-sdt-full/
│           ├── cortexa53-linux.dts
│           └── pl-overlay-full/
│               └── pl.dtso
|   ------------------------------------------------------------------------------
├── hw/
│   └── sdt/                        # 입력 SDT 전체와 .bit 파일
├── recipes-core/
│   └── images/
│       └── kv260-image.bb
├── recipes-firmware/
│   └── kv260-pl-firmware/
│       └── kv260-pl-firmware_1.0.bb
└── scripts/
    └── gen-machine.sh
```
<br>

> [WARNING]  
> **`gen-machine-conf`로 생성된 파일은 직접 수정하지 마세요.**
> 스크립트를 다시 실행하면 수동 변경 내용이 덮어써질 수 있습니다. 하드웨어 변경은 `hw/sdt/`에 반영한 뒤 `gen-machine.sh`로 다시 생성하세요.

## 새로운 SDT 적용 방법
만약, PL의 변경사항이 발생한 경우 다음의 순서를 통해 Layer에 적용합니다.
1. XSA로부터 SDT를 추출하여 SDT내 파일들을 'sdt'폴더 안에 복사하여 내용을 교채합니다.
2. EDF의 Yocto 개발 환경울 활성화합니다.
    ```bash
    source ./edf-init-build-env build
    ```
3. gen-machine.sh를 실행하여 meta-kv260 Layer에 새로운 SDT를 적용합니다.
    ```bash
    ../sources/meta-kv260/scripts/gen-machine.sh
    ```

<br>

## KV260 설정
### 1. KV260_MACHINE_NAME
Yocto에서 사용할 MACHINE의 이름을 설정


## 이미지 레시피의 역할

### 1. kv260-image.bb

[kv260-image.bb](recipes-core/images/kv260-image.bb)는 SDT 기반 KV260 Linux 이미지의 구성을 정의합니다.

### 2. kv260-pl-firmware_1.0.bb

[kv260-pl-firmware_1.0.bb](recipes-firmware/kv260-pl-firmware/kv260-pl-firmware_1.0.bb)는 SDT의 `.bit`와 생성된 `.dtso`를 `.bin`, `.dtbo`로 변환하여 Linux 이미지에 포함할 PL 펌웨어를 패키징합니다.

두 레시피는 `zynqmp-kv260-sdt-full` 머신을 대상으로 합니다. 이미지의 루트 파일 시스템에는 다음 PL 파일이 설치됩니다.

```text
/lib/firmware/xilinx/kv260-pl-firmware/
├── kv260-pl-firmware.bin
└── kv260-pl-firmware.dtbo
```

`.bin`은 FPGA의 PL 회로를 구성하는 비트스트림이고, `.dtbo`는 해당 PL 장치를 Linux에 등록하는 디바이스 트리 오버레이입니다. 현재 레이어는 파일과 로딩 도구를 이미지에 포함하며, 부팅 시 자동 로딩 서비스는 포함하지 않습니다.
