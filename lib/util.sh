#!/usr/bin/env bash
error() {
    echo -e "\e[91m${*}\e[m"
}

info() {
    echo -e "\e[96m${*}\e[m"
}

ok() {
    echo -e "\e[92m${*}\e[m"
}

die() {
    error "${*}"
    exit 0
    umount_chroot "$(dirname "${0}")/work/rootfs"
}

check_deps() {
    info "- Checking dependencies"
    for DEP in ${*}; do
        info "-- Checking for dependency ${DEP}"
        if [[ ! $(command -v "${DEP}") ]]; then
            die "--- Dependency ${DEP} not found!"
        fi
    done
}

mount_chroot() {
    mount --bind /dev "${1}/dev"
    mount --bind /run "${1}/run"
    mount -t sysfs /sys "${1}/sys"
    mount -t proc /proc "${1}/proc"
}

umount_chroot() {
    for D in proc dev sys run; do
        umount -R "${1}/${D}"
    done
}
