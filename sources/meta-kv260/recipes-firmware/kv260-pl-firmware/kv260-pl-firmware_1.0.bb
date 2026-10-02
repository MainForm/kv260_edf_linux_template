SUMMARY = "KV260 PL bitstream and device tree overlay"
DESCRIPTION = "Package the SDT bitstream and generated PL overlay for runtime loading."
LICENSE = "CLOSED"

inherit dfx_user_dts

COMPATIBLE_MACHINE = "^zynqmp-kv260-sdt-full$"

# Read the original bitstream and gen-machine.sh output without duplicating them.
FILESEXTRAPATHS:prepend := "${THISDIR}/../../hw/sdt:${THISDIR}/../../conf/dts/${KV260_MACHINE_NAME}/pl-overlay-full:"

SRC_URI = " \
    file://kv260_led_test.bit \
    file://pl.dtso \
"

DT_FILES = "pl.dtso"
