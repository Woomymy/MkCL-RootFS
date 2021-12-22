#!/usr/bin/env bash

set -eo pipefail

source "$(dirname $0)/lib/util.sh"

[[ "$(id -u)" == "0" ]] || die "This script must be executed as root!"

check_deps file 7z unsquashfs

ISO="${1}"

[[ ! -f "${ISO}" ]] && {
    die "- Iso file ${ISO} not found!"
}

ISO="$(realpath "${ISO}")"

ISO_MIME="$(file -b --mime-type "${ISO}")"
if [[ ! "${ISO_MIME}" =~ ^application/x-iso9660-image$ ]]; then
    die "- Iso file has invalid mime type: ${ISO_MIME}"
fi

ok "- Making Calculate RootFS from ISO ${ISO}"
info "-- Iso Infos:"
info "--- Size: $(du -sh "${ISO}")"
info "--- Mime type: ${ISO_MIME}"
info "--- SHA256 Checksum: $(sha256sum "${ISO}")"
info "--- File name: ${ISO}"

WORKDIR="$(realpath "$(dirname $0)/work")"

if [[ "$(mount | grep "${WORKDIR}")" ]]; then
    umount_chroot "${WORKDIR}/rootfs"
fi

if [[ -e "${WORKDIR}" ]]; then
    rm -rf "${WORKDIR}"
fi

mkdir "${WORKDIR}"
cd "${WORKDIR}"

info "- Extracting ${ISO} in ${WORKDIR}"

info "-- Copying ${ISO} in ${WORKDIR}"
cp "${ISO}" "${WORKDIR}"

info "-- Using 7zip to extract ${ISO}"
7z x ${ISO}

info "-- Extracting livecd.squashfs"
unsquashfs -d "${WORKDIR}/rootfs" "${WORKDIR}/livecd.squashfs" || true

echo "- Cleaning up rootfs"

ROOTFS="${WORKDIR}/rootfs"

cd "${ROOTFS}"

echo "-- Minimalising calculate-utils"
echo "sys-apps/calculate-utils -install" >>"${ROOTFS}/etc/portage/package.use"

echo "nameserver 9.9.9.9" >"${ROOTFS}/etc/resolv.conf"
echo "-- Removing packages"
mount_chroot "${ROOTFS}"
chroot "${ROOTFS}" emerge -C sys-apps/calculate-utils
chroot "${ROOTFS}" emerge sys-apps/calculate-utils
chroot "${ROOTFS}" emerge -C virtual/ssh virtual/linux-sources sys-fs/reiserfsprogs sys-fs/xfsprogs sys-fs/btrfs-progs sys-fs/e2fsprogs sys-fs/f2fs-tools sys-boot/grub sys-boot/efibootmgr sys-boot/gnu-efi sys-boot/os-prober app-misc/tmux sys-kernel/dracut sys-fs/cryptsetup media-gfx/gfxboot-themes-calculate net-fs/nfs-utils app-crypt/sbsigntools app-text/tree app-crypt/shim-signed media-fonts/terminus-font net-misc/dhcp virtual/service-manager sys-apps/openrc sys-apps/sysvinit || die "Can't remove packages in chroot!"
chroot "${ROOTFS}" emerge -c
umount_chroot "${ROOTFS}"

echo "-- Removing kernel / initrd"
rm -rf "${ROOTFS:?}/boot/"*
rm -rf "${ROOTFS:?}/lib/modules/"*

echo "-- Removing distfiles / packages"
rm -rf "${ROOTFS}/var/calculate/tmp/portage/"
mkdir "${ROOTFS}/var/calculate/tmp/portage"
rm -rf "${ROOTFS}/var/calculate/distfiles/"*
rm -rf "${ROOTFS}/var/calculate/packages/$(arch)/"*
rm -rf "${ROOTFS}/var/log/"*
rm -rf "${ROOTFS}/run/"*
rm -rf "${ROOTFS}/dev/"*

echo "- Packing rootfs.tar.xz"
tar cJvf "${WORKDIR}/rootfs.tar.xz" *
