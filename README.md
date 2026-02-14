# BareMetalInitialization

## English
### What it does
Automates unattended Debian install testing by:
1. injecting preseed/grub config into a Debian ISO,
2. rebuilding the ISO,
3. boot-testing with KVM/libvirt.

### Requirements
- Linux host
- POSIX shell (`/bin/sh`)
- `sudo`, `xorriso`, `cpio`, `gzip`, `md5sum`, `busybox`
- `isolinux`, `syslinux`
- KVM/libvirt tools: `virt-install`, `virsh`

### Configuration (single source)
1. Copy config template:
```sh
cp config/project.env.example config/project.env
```
2. Edit `config/project.env` only.
3. All scripts auto-load `config/project.env`.

### Where to put Debian ISO
Place your local ISO at:
```text
local/iso/debian-12.11.0-amd64-DVD-1.iso
```
Or change `DEBIAN_ISO_PATH` in `config/project.env`.

Do not commit ISO files.

### How to run
Build custom ISO:
```sh
./scripts/build_iso.sh
```
Run KVM unattended test:
```sh
./scripts/test_iso_kvm.sh
```
Serve preseed over HTTP:
```sh
./scripts/serve_preseed.sh
```

### Expected results
- Custom ISO: `build/auto-debian.iso`
- Temporary extraction dir: `build/isofiles/` (removed after build)
- VM disks under libvirt image dir (when test script runs)

### Troubleshooting
- `Config file not found`: create `config/project.env` from example.
- `Debian ISO not found`: fix `DEBIAN_ISO_PATH` or put ISO in `local/iso/`.
- Missing command errors: install required packages.
- `busybox` missing: required for `scripts/serve_preseed.sh`.

---

## 中文
### 项目功能
本项目用于 Debian 无人值守安装自动化：
1. 将 preseed/grub 配置注入 Debian ISO，
2. 重新打包生成新 ISO，
3. 用 KVM/libvirt 启动并测试自动安装。

### 依赖要求
- Linux 主机
- POSIX shell（`/bin/sh`）
- `sudo`、`xorriso`、`cpio`、`gzip`、`md5sum`、`busybox`
- `isolinux`、`syslinux`
- KVM/libvirt 工具：`virt-install`、`virsh`

### 配置方式（单一配置源）
1. 复制模板：
```sh
cp config/project.env.example config/project.env
```
2. 仅编辑 `config/project.env`。
3. 所有脚本会自动读取该文件。

### Debian ISO 放置位置
本地 ISO 默认放在：
```text
local/iso/debian-12.11.0-amd64-DVD-1.iso
```
也可在 `config/project.env` 中修改 `DEBIAN_ISO_PATH`。

不要把 ISO 提交到仓库。

### 运行方式
构建自定义 ISO：
```sh
./scripts/build_iso.sh
```
执行 KVM 自动安装测试：
```sh
./scripts/test_iso_kvm.sh
```
启动 preseed HTTP 服务：
```sh
./scripts/serve_preseed.sh
```

### 预期结果
- 输出 ISO：`build/auto-debian.iso`
- 临时目录：`build/isofiles/`（构建后自动删除）
- 运行测试后在 libvirt 镜像目录生成 qcow2 磁盘

### 快速排障
- `Config file not found`：先从 example 复制 `config/project.env`。
- `Debian ISO not found`：检查 `DEBIAN_ISO_PATH` 或 ISO 放置路径。
- 缺少命令：安装依赖包。
- 缺少 `busybox`：`scripts/serve_preseed.sh` 必需。
