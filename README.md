# kbuild | kernel build script for dev/hacking
simple script for building the kernel for development and hacking purposes,
script is designed for `x86_64` builds, but you can easily change that
by doing a little bit of editing

### building 
to build a specific version with `x86_64_defconfig` and `CONFIG_DEBUG_INFO=y`,
just specify the version, for example:
```bash
./kbuild.sh 5.15.135
```
you can also build the staging kernel using `git` as the version

to build using a specific config, specify config's path at the end:
```bash
./kbuild.sh 5.15.135 my-cool-config
```

### booting
you can also boot the kernel you built with QEMU/KVM, using the `kboot` script:
```bash
./kboot.sh 5.15.135 
```

by default, this script will build busybox for initramfs, however you can specify
a path to your own initramfs:
```bash
./kboot.sh 5.15.135 my-cool-initramfs.cpio.gz 
```
note that this will extract the initramfs to install the kernel modules
