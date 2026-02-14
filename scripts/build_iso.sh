#!/bin/sh

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
CONFIG_FILE=${PROJECT_CONFIG_FILE:-${PROJECT_ROOT}/config/project.env}

if [ ! -f "$CONFIG_FILE" ]; then
  echo "[ERROR] Config file not found: $CONFIG_FILE"
  echo "Create it from: ${PROJECT_ROOT}/config/project.env.example"
  exit 1
fi

# shellcheck disable=SC1091
. "$CONFIG_FILE"

require_var() {
  var_name="$1"
  eval "var_value=\${$var_name-}"
  if [ -z "$var_value" ]; then
    echo "[ERROR] Missing required config: $var_name"
    exit 1
  fi
}

for v in \
  REQUIRED_PACKAGES \
  DEBIAN_ISO_PATH PRESEED_CFG GRUB_CFG BUILD_DIR OUTPUT_ISO_NAME ISOFILES_DIR_NAME \
  ISO_GRUB_TARGET_PATH ISO_INSTALL_DIR ISO_INITRD_GZ_PATH ISO_INITRD_PATH ISO_MD5_FILE \
  XORRISO_VOLUME_ID XORRISO_ISOLINUX_BIN XORRISO_BOOT_CAT XORRISO_EFI_IMG ISOHYBRID_MBR
 do
  require_var "$v"
done

resolve_path() {
  p="$1"
  case "$p" in
    /*) echo "$p" ;;
    *) echo "${PROJECT_ROOT}/$p" ;;
  esac
}

check_packages() {
  missing_packages=""
  for pkg in $REQUIRED_PACKAGES; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      missing_packages="${missing_packages} ${pkg}"
    fi
  done
  echo "$missing_packages"
}

missing_packages=$(check_packages)
if [ -n "$missing_packages" ]; then
  sudo apt update
  sudo apt install -y $missing_packages
fi

ISO_PATH=$(resolve_path "$DEBIAN_ISO_PATH")
PRESEED_PATH=$(resolve_path "$PRESEED_CFG")
GRUB_PATH=$(resolve_path "$GRUB_CFG")
BUILD_PATH=$(resolve_path "$BUILD_DIR")
ISOFILES_PATH=${BUILD_PATH}/${ISOFILES_DIR_NAME}
OUTPUT_ISO_PATH=${BUILD_PATH}/${OUTPUT_ISO_NAME}

if [ ! -f "$ISO_PATH" ]; then
  echo "[ERROR] Debian ISO not found: $ISO_PATH"
  echo "Set DEBIAN_ISO_PATH in config/project.env"
  exit 1
fi

if [ ! -f "$PRESEED_PATH" ]; then
  echo "[ERROR] Preseed file not found: $PRESEED_PATH"
  exit 1
fi

if [ ! -f "$GRUB_PATH" ]; then
  echo "[ERROR] GRUB file not found: $GRUB_PATH"
  exit 1
fi

mkdir -p "$BUILD_PATH"

if [ -d "$ISOFILES_PATH" ]; then
  rm -rf "$ISOFILES_PATH"/*
fi

xorriso -osirrox on -indev "$ISO_PATH" -extract / "$ISOFILES_PATH"/

sudo cp -f "$GRUB_PATH" "$ISOFILES_PATH/$ISO_GRUB_TARGET_PATH"

chmod +w -R "$ISOFILES_PATH/$ISO_INSTALL_DIR"
gunzip "$ISOFILES_PATH/$ISO_INITRD_GZ_PATH"
(
  cd "$(dirname "$PRESEED_PATH")" || exit 1
  echo "$(basename "$PRESEED_PATH")" | cpio -H newc -o -A -F "$ISOFILES_PATH/$ISO_INITRD_PATH"
)

gzip "$ISOFILES_PATH/$ISO_INITRD_PATH"
chmod -w -R "$ISOFILES_PATH/$ISO_INSTALL_DIR"

chmod a+x -R "$ISOFILES_PATH/"
chmod a+w "$ISOFILES_PATH/$ISO_MD5_FILE"

(
  cd "$ISOFILES_PATH" || exit 1
  md5sum $(find -follow -type f) > "$ISO_MD5_FILE"
)

chmod a-w "$ISOFILES_PATH/$ISO_MD5_FILE"

xorriso -as mkisofs \
  -V "$XORRISO_VOLUME_ID" \
  -o "$OUTPUT_ISO_PATH" \
  -r -J -l -b "$XORRISO_ISOLINUX_BIN" \
  -c "$XORRISO_BOOT_CAT" \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot \
  -e "$XORRISO_EFI_IMG" \
  -no-emul-boot \
  -isohybrid-mbr "$ISOHYBRID_MBR" \
  "$ISOFILES_PATH"

sudo rm -rf "$ISOFILES_PATH/"

echo "[OK] Built ISO: $OUTPUT_ISO_PATH"
