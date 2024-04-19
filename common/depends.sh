#!/bin/bash

cmdlist=(
  "gcc.GCC" "make.make" "ld.binutils" "flex.Flex" "bison.Bison"
  "pahole.pahole" "bindgen/cbindgen.bindgen/cbindgen" "mount.util-linux" "depmod.kmod"
  "e2fsck.e2fsprogs" "ps.procps" "openssl.OpenSSL" "bc.bc" "cpio.cpio" "tar.tar" "git.git"
)

for c in "${cmdlist[@]}"; do
  cmd=$(echo $c | cut -d. -f1)
  name=$(echo $c | cut -d. -f2)
  
  cmd1=$(echo $cmd | cut -d/ -f1)
  cmd1=$(echo $cmd | cut -d/ -f2)

  if ! command -v $cmd1 &> /dev/null; then
    if [ -z "$cmd2" ] || ! command -v $cmd2 &> /dev/null; then
      error "$name is not found, and its required for the build"
      exit 1
    fi
  fi
done
