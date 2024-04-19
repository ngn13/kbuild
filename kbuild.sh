#!/bin/bash

# kbuild | build the kernel for dev/hacking 
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
CONFIG="${2}"

if [ ! -z "$CONFIG" ]; then
  if [ ! -f "$CONFIG" ]; then
    error "Failed to load the configuration, check the path you specified"
    exit 1
  fi
  info "Using custom configuration for the build ($CONFIG)"
fi

## check the url for the kernel archive
if [[ "$VERSION" == *"rc"* ]]; then
  ARC_URL="https://git.kernel.org/torvalds/t/linux-${VERSION}.tar.gz"
  arc_code="$(curl -L -I -o /dev/null -s -w "%{http_code}" $ARC_URL)"
  
  get_file "${ARC_URL}"
  ARC_FILE="$file"
  
  if [ "$arc_code" != "200" ]; then
    error "Failed to access the kernel archive URL"
    exit 1
  fi
elif [ "$VERSION" != "staging" ]; then
  ARC_URL="https://cdn.kernel.org/pub/linux/kernel/v${MAJOR}.x/linux-${VERSION}.tar.xz"
  arc_code="$(curl -I -o /dev/null -s -w "%{http_code}" $ARC_URL)"
  
  get_file "${ARC_URL}"
  ARC_FILE="$file"

  SIG_URL="https://cdn.kernel.org/pub/linux/kernel/v${MAJOR}.x/linux-${VERSION}.tar.sign"
  sig_code="$(curl -I -o /dev/null -s -w "%{http_code}" $SIG_URL)"
  
  get_file "${SIG_URL}"
  SIG_FILE="$file"

  if [ "$arc_code" != "200" ]; then
    error "Failed to access the kernel archive URL"
    exit 1
  fi
  
  if [ "$sig_code" != "200" ]; then
    error "Failed to access the kernel signature URL"
    exit 1
  fi
fi

## setup the build dir
BUILD_DIR="builds/${VERSION}"
rm -rf "$BUILD_DIR"
mkdir -p $BUILD_DIR
cd $BUILD_DIR

## download and decompress the archive
if [ -z "$ARC_URL" ]; then
  info "Cloning the git repo, this may take a while"
  git clone -b staging-testing git://git.kernel.org/pub/scm/linux/kernel/git/gregkh/staging.git .
else
  info "Downloading the kernel archive"
  download "$ARC_URL"
  check_ret "Failed to download the archive"

  if [ ! -z "$SIG_URL" ]; then
    info "Downloading the archive signature"

    download "$SIG_URL"
    check_ret "Failed to download the signature"
 
    info "Importing GPG pubkeys for signature verification"
    gpg --locate-keys torvalds@kernel.org gregkh@kernel.org > /dev/null
    check_ret "Failed to get import GPG pubkeys"

    info "Decompressing XZ archive for signature verification"
    xz -d "$ARC_FILE"
    check_ret "Failed to decompress the archive with xz"

    gpg --verify "$SIG_FILE" 2> /dev/null
    check_ret "Signature verification failed, archive is corrupted or the upstream is hijacked"
    success "Signature verification was successful"

    remove_ext "$ARC_FILE" 
    ARC_FILE="${file}"
    
    rm "$SIG_FILE"
  fi

  tar xf "$ARC_FILE"
  check_ret "Failed to extract the TAR archive"
  rm "$ARC_FILE"

  remove_ext "$ARC_FILE"
  ARC_FILE="${file}"

  mv "${ARC_FILE}/"* . 
  rm -r "$ARC_FILE"
fi

## load kernel config
if [ ! -z "$CONFIG" ]; then
  info "Copying over the configuration"
  cp "${CONFIG}" .config
  make olddefconfig
else
  info "Using default configuration"
  make x86_64_defconfig
  check_ret "Failed to create the default config"
  sed -i "s/CONFIG_DEBUG_INFO=n/CONFIG_DEBUG_INFO=y/g" .config
fi

## start the build
info "Starting the build at $(date +%T)"
SECONDS=0

make -j$(nproc)
check_ret "Build failed"

passed=$SECONDS
success "Completed build at $(date +%T) ($($passed / 60)m and $($passed % 60)s)"
