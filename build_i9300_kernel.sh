#!/bin/bash
TOPDIR=$(cd $(dirname "$0"); pwd)
#TCHAIN=/opt/toolchains/arm-eabi-linaro-4.7.3/bin/arm-eabi-
TCHAIN=/opt/toolchains/arm-eabi-linaro-4.6.2/bin/arm-eabi-
#TCHAIN=/opt/toolchains/arm-eabi-4.4.3/bin/arm-eabi-
JNUM=`cat /proc/cpuinfo | grep processor | wc -l`
DATE_STR=`date '+%d%m%y'`

# colors
red=$(tput setaf 1)
ylw=$(tput setaf 3)
cya=$(tput setaf 6)
blu=$(tput setaf 4)
txtrst=$(tput sgr0)

clear

export ARCH=arm
export CROSS_COMPILE=${TCHAIN}

# if there was an error
if [ -f ${TOPDIR}/.kberror.txt ]; then
    rm -f ${TOPDIR}/.kberror.txt
else
    # clean kernel directory
    echo "${cya}Cleaning ${TOPDIR}...${txtrst}"
    make clean && make mrproper
    make lupus_i9300_defconfig
fi


# clean from previous build
if [ -d ${TOPDIR}/modules ]; then 
    rm -f ${TOPDIR}/modules/*
else
    mkdir -p ${TOPDIR}/modules
fi

if [ -e ${TOPDIR}/ramdisk.cpio.gz ]; then
rm -f ${TOPDIR}/ramdisk.cpio.gz
fi

if [[ -e ${TOPDIR}/previous_boot.img ]] && [[ -e ${TOPDIR}/boot.img ]]; then
rm -f ${TOPDIR}/previous_boot.img
fi

if [ -e ${TOPDIR}/boot.img ]; then
mv ${TOPDIR}/boot.img ${TOPDIR}/previous_boot.img
fi

if [ -e ${TOPDIR}/LuPuS_*.zip ]; then
rm -f ${TOPDIR}/LuPuS_*.zip
fi


make -j${JNUM}

# if there was an error exit
if [ "$?" -ne "0" ]; then
    echo "${red} == [ERROR] ==${txtrst}"
    echo "build_error" > ${TOPDIR}/.kberror.txt
    echo; echo; read -p "${ylw}Press [ENTER] to exit..${txtrst}"
    exit 1
fi

echo; echo "Copying modules to ${TOPDIR}/modules"; echo; echo
echo ${blu}; find -name '*.ko' -exec cp -av {} ${TOPDIR}/modules/ \;; echo ${txtrst}

# strip modules
if [ -d ${TOPDIR}/ramdisk/lib/modules ]; then
rm -rf ${TOPDIR}/ramdisk/lib/modules
fi

${TCHAIN}strip --strip-unneeded ${TOPDIR}/modules/*
cp -r ${TOPDIR}/modules ${TOPDIR}/ramdisk/lib


echo; echo "${cya}Creating boot.img..${txtrst}"; echo
# compress ramdisk
./mkbootfs ${TOPDIR}/ramdisk | gzip -9 > ${TOPDIR}/ramdisk.cpio.gz

# creatinf boot.img
./mkbootimg --kernel ${TOPDIR}/arch/arm/boot/zImage --ramdisk ramdisk.cpio.gz --board smdk4x12 --base 0x10000000 --pagesize 2048 --ramdiskaddr 0x11000000 -o ${TOPDIR}/boot.img

cp ${TOPDIR}/default_kernel.zip ${TOPDIR}/LuPuS_${DATE_STR}.zip
zip -rq LuPuS_${DATE_STR}.zip boot.img
