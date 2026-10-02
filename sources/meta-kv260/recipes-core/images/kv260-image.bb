require recipes-extended/images/edf-linux-disk-image.bb

SUMMARY = "KV260 custom SDT Linux image"

COMPATIBLE_MACHINE = "^zynqmp-kv260-sdt-full$"

IMAGE_INSTALL:append = " kv260-pl-firmware fpga-manager-script"