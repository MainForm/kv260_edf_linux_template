#!/usr/bin/env bash

if ! command -v repo >/dev/null 2>&1; then
    echo "오류: repo 명령을 찾을 수 없습니다. repo를 설치하고 PATH에 추가해 주세요." >&2
    echo "설치 방법은 README.md의 'repo 설치 및 PATH 설정'을 참고하세요." >&2
    exit 1
fi

# AMD manifest 저장소로 repo 작업 공간 초기화
repo init -u https://github.com/Xilinx/yocto-manifests.git \
  -b rel-v2026.1 -m default-edf.xml

# 이 프로젝트가 관리하는 고정 manifest를 적용
cp manifests/edf-pinned.xml .repo/manifests/edf-pinned.xml
repo init -m edf-pinned.xml

# 고정된 커밋의 외부 소스 다운로드
repo sync -j4
