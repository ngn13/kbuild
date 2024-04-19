#!/bin/bash

# kboot | build the kernel for dev/hacking 
# Written by ngn (https://ngn.tf) (2024)

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

## import common scripts
if [ ! -d "common" ]; then
  echo "You should run this script inside the repo's directory"
  exit 1
fi

source common/log.sh
source common/util.sh
source common/depends.sh

## check QEMU/KVM
qemu="qemu-system-x86_64"
if ! command -v $qemu &> /dev/null; then
  qemu="kvm"
fi

if ! command -v $qemu &> /dev/null; then
  error "Failed to find x86_64 QEMU/KVM"
  exit 1
fi

## check & load args
if [ -z "$1" ]; then
  error "Please specify a kernel version, for example:"
  print "    $0 5.15.135"
  exit 1
fi

if [ "${1}" != "staging" ]; then
  load_version "${1}"
  check_ret "Invalid version number"
fi

VERSION="${1}"
INITFS="${2}"

if [ -z "${2}" ]; then
  INITFS="builds/initramfs.cpio.gz"
elif [ ! -z "${2}" ] && [ ! -f "${2}" ]; then
  error "Failed access the initramfs, check the path you specified" 
  exit 1
fi

INITFS="$(realpath $INITFS)"

BZIMG="builds/${VERSION}/arch/x86_64/boot/bzImage"
if [ ! -f "$BZIMG" ]; then
  error "Failed to find the bzImage for the specified version, have you built it yet?"
  exit 1
fi

rm -rf builds/temp
rm -f builds/initramfs_temp.cpio.gz

## build the initfs
if [ ! -f "$INITFS" ]; then
  old_pwd="${PWD}"
  BUILD_DIR="builds/busybox"
  rm -rf "$BUILD_DIR"
  mkdir -p $BUILD_DIR
  cd $BUILD_DIR

  info "Downloading busybox archive"
  download https://www.busybox.net/downloads/busybox-1.36.1.tar.bz2
  
  info "Downloading busybox archive signature"
  download https://www.busybox.net/downloads/busybox-1.36.1.tar.bz2.sig

  gpg --receive-keys 47B70C55ACC9965B # https://busybox.net/~vda/vda_pubkey.gpg
  gpg --verify "busybox-1.36.1.tar.bz2.sig" 2> /dev/null
  check_ret "Signature verification failed, archive is corrupted or the upstream is hijacked"
  success "Signature verification was successful"

  info "Extracting busybox"
  tar xf "busybox-1.36.1.tar.bz2"
  check_ret "Failed to extract the busybox archive"

  mv "busybox-1.36.1/"* .
  rm -r "busybox-1.36.1"
  rm "busybox-1.36.1.tar.bz2"
  rm "busybox-1.36.1.tar.bz2.sig"

  #cp "${old_pwd}/common/busybox.in" Config.in 
  info "Creating the default config"
  make defconfig
  check_ret "Failed to create the default config"
  echo "CONFIG_STATIC=y" >> .config

  info "Starting the build at $(date +%T)"
  SECONDS=0

  make -j$(nproc)
  check_ret "Build failed"

  passed=$SECONDS
  success "Completed build at $(date +%T) ($($passed / 60)m and $($passed % 60)s)"

  info "Creating the root filesystem for the initramfs"
  mkdir -p temproot/proc
  mkdir -p temproot/lib
  mkdir -p temproot/dev
  mkdir -p temproot/sys
  mkdir -p temproot/bin
  mkdir -p temproot/tmp

  install -m755 "${old_pwd}/files/init.sh" temproot/init
  cp busybox temproot/bin

  pushd temproot/bin > /dev/null
    for c in $(./busybox --list); do 
      ln -s /bin/busybox ./$c
    done
  popd > /dev/null

  pushd temproot > /dev/null
    info "Creating the initramfs with cpio and gzip"
    find . | cpio -o --format=newc | gzip -9 > "${old_pwd}/builds/initramfs.cpio.gz"
    check_ret "Failed to create the initramfs archive"
  popd > /dev/null

  success "Successfuly created the initramfs archive"
  cd "${old_pwd}"
fi

mkdir -p builds/temp
pushd builds/temp > /dev/null
  zcat "${INITFS}" | cpio -i
  check_ret "Failed to extract the initramfs archive"
popd > /dev/null

pushd "builds/${VERSION}" > /dev/null 
  make INSTALL_MOD_PATH=../temp modules_install
  check_ret "Failed to install kernel modules"
popd > /dev/null

pushd builds/temp > /dev/null
  find . | cpio -o --format=newc | gzip -9 > "../initramfs_temp.cpio.gz"
  check_ret "Failed to rebuild the initramfs archive"
popd > /dev/null

info "Booting the kernel with the initramfs using QEMU/KVM"
$qemu -kernel "${BZIMG}" -initrd builds/initramfs_temp.cpio.gz \
  -nographic -append "console=ttyS0 nokaslr" -s
check_ret "Failed to boot using QEMU/KVM"

rm builds/initramfs_temp.cpio.gz
rm -r builds/temp
