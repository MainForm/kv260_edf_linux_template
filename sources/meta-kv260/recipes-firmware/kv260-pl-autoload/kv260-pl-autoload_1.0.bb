SUMMARY = "Load KV260 PL firmware at boot"
DESCRIPTION = "Load the KV260 bitstream and device tree overlay using systemd."
LICENSE = "CLOSED"

COMPATIBLE_MACHINE = "^zynqmp-kv260-sdt-full$"

SRC_URI = "file://kv260-pl-autoload.service"

inherit systemd

RDEPENDS:${PN} = "kv260-pl-firmware fpga-manager-script"

SYSTEMD_SERVICE:${PN} = "kv260-pl-autoload.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/kv260-pl-autoload.service \
        ${D}${systemd_system_unitdir}/kv260-pl-autoload.service
}