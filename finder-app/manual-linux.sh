#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
SYSROOT=$(aarch64-none-linux-gnu-gcc -print-sysroot)

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    # clean 
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    #build default .config
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    #build the kernle image
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
# Create rootfs directory
mkdir -p ${OUTDIR}/rootfs
cd ${OUTDIR}/rootfs
# Create base directories inside rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log
mkdir -p home/conf

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make distclean
    make defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

cd ${OUTDIR}/rootfs
echo "Library dependencies"

PROGRAM_INTERPRETER=$(${CROSS_COMPILE}readelf -a bin/busybox | \
    grep "program interpreter" | \
    awk '{print $NF}' | tr -d ']')

mapfile -t SLIBS < <(${CROSS_COMPILE}readelf -a bin/busybox | \
    grep "Shared library" | \
    awk '{print $NF}' | tr -d '[]')

# Copy program interpreter
cp -a ${SYSROOT}${PROGRAM_INTERPRETER} ${OUTDIR}/rootfs/lib

# Copy shared libraries
for lib in "${SLIBS[@]}"
do
    if [ -f ${SYSROOT}/lib/${lib} ]; then
        cp -a ${SYSROOT}/lib/${lib} ${OUTDIR}/rootfs/lib
    elif [ -f ${SYSROOT}/lib64/${lib} ]; then
        cp -a ${SYSROOT}/lib64/${lib} ${OUTDIR}/rootfs/lib64
    else
        echo "Warning: ${lib} not found in sysroot"
    fi
done
# TODO: Make device nodes

cd ${OUTDIR}/rootfs
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1

# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}
make clean 
make writer CROSS_COMPILE=aarch64-none-linux-gnu-

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
echo "Copying finder application files"
cp -a ${FINDER_APP_DIR}/finder.sh ${OUTDIR}/rootfs/home/
cp -a ${FINDER_APP_DIR}/finder-test.sh ${OUTDIR}/rootfs/home/
cp -a ${FINDER_APP_DIR}/writer ${OUTDIR}/rootfs/home/

cp -a ${FINDER_APP_DIR}/conf/* ${OUTDIR}/rootfs/home/conf
cp -a ${FINDER_APP_DIR}/autorun-qemu.sh ${OUTDIR}/rootfs/home/

# TODO: Chown the root directory
cd ${OUTDIR}/rootfs
sudo chown -R root:root *

# TODO: Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio 
cd ${OUTDIR}
gzip -f initramfs.cpio

