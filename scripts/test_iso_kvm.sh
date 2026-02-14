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
  BUILD_SCRIPT BUILD_DIR OUTPUT_ISO_NAME \
  VM_NAME LIBVIRT_IMAGE_DIR \
  SYSTEM_DISK_NAME DATA_DISK_NAME \
  SYSTEM_DISK_SIZE_GB DATA_DISK_SIZE_GB \
  VM_MEMORY_MB VM_VCPUS OS_VARIANT BRIDGE_NAME SPICE_PASSWORD
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

BUILD_SCRIPT_PATH=$(resolve_path "$BUILD_SCRIPT")
BUILD_PATH=$(resolve_path "$BUILD_DIR")
LOCAL_ISO_PATH=${BUILD_PATH}/${OUTPUT_ISO_NAME}
TARGET_ISO_PATH=${LIBVIRT_IMAGE_DIR}/${OUTPUT_ISO_NAME}
SYSTEM_DISK_PATH=${LIBVIRT_IMAGE_DIR}/${SYSTEM_DISK_NAME}
DATA_DISK_PATH=${LIBVIRT_IMAGE_DIR}/${DATA_DISK_NAME}

sudo virsh destroy "$VM_NAME"
sudo virsh undefine "$VM_NAME" --nvram

sudo rm -rf "$SYSTEM_DISK_PATH"
sudo rm -rf "$DATA_DISK_PATH"
sudo rm -rf "$LOCAL_ISO_PATH"
sudo rm -rf "$TARGET_ISO_PATH"

sudo /bin/sh "$BUILD_SCRIPT_PATH"

sudo mv -f "$LOCAL_ISO_PATH" "$LIBVIRT_IMAGE_DIR/"

sudo virt-install \
  --name "$VM_NAME" \
  --memory "$VM_MEMORY_MB" \
  --vcpus="$VM_VCPUS" \
  --disk path="$DATA_DISK_PATH",size="$DATA_DISK_SIZE_GB",format=qcow2,cache=none,bus=sata,target.dev=sda \
  --disk path="$SYSTEM_DISK_PATH",size="$SYSTEM_DISK_SIZE_GB",format=qcow2,cache=none,bus=virtio,target.dev=vda \
  --cdrom "$TARGET_ISO_PATH" \
  --os-variant "$OS_VARIANT" \
  --network bridge:"$BRIDGE_NAME" \
  --video qxl \
  --channel spicevmc \
  --graphics spice,listen=0.0.0.0,password="$SPICE_PASSWORD" \
  --boot uefi
