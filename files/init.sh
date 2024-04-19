#!/bin/sh
# simple init script for busybox initramfs

mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs udev /dev 
sysctl -w kernel.printk="2 4 1 7"

clear
echo "welcome to kbuild initramfs!" 
echo "anyway let me get you a shell"
/bin/sh

poweroff -f
