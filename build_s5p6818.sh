#!/bin/bash

set -e

TOP=`pwd`
export TOP

source ${TOP}/device/nexell/tools/common.sh
source ${TOP}/device/nexell/tools/dir.sh
source ${TOP}/device/nexell/tools/make_build_info.sh

BOARD=$(get_board_name $0)

parse_args -b ${BOARD} $@
print_args
setup_toolchain
export_work_dir
patches

echo "BOARD ${BOARD} $0 $1 $2"
CROSS_COMPILE=
if [ "${TARGET_SOC}" == "s5p6818" ]; then
	CROSS_COMPILE="aarch64-linux-android-"
	# CROSS_COMPILE32="arm-eabi-"
	CROSS_COMPILE32="arm-linux-gnueabihf-"
else
	CROSS_COMPILE="arm-eabi-"
fi

OPTEE_BUILD_OPT="PLAT_DRAM_SIZE=2048 PLAT_UART_BASE=0xc00a3000 SECURE_ON=0 SUPPORT_ANDROID=1"
OPTEE_BUILD_OPT+=" CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE32=${CROSS_COMPILE32}"
OPTEE_BUILD_OPT+=" UBOOT_DIR=${UBOOT_DIR}"

declare -a security=("testkey" "shared" "media" "release" "platform")

function generate_key()
{
	echo "key generation for ${TARGET_SOC}_${BOARD_NAME}"
	if ! [ -d ${TOP}/device/nexell/${BOARD_NAME}/signing_keys ];then
		mkdir -p ${TOP}/device/nexell/${BOARD_NAME}/signing_keys
	fi

	for i in ${security[@]}
	do
		if [ ! -e  ${TOP}/device/nexell/${BOARD_NAME}/signing_keys/$i.pk8 ];then
			${TOP}/device/nexell/${BOARD_NAME}/mkkey.sh $i ${BOARD_NAME}
		fi
	done
	echo "End of generate_key"
}

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_BL1}" == "true" ]; then
	build_bl1 ${BL1_DIR}/bl1-${TARGET_SOC} avn 2
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_UBOOT}" == "true" ]; then
	build_uboot ${UBOOT_DIR} ${TARGET_SOC} ${BOARD} ${CROSS_COMPILE}

	if [ "${BUILD_UBOOT}" == "true" ]; then
		build_optee ${OPTEE_DIR} "${OPTEE_BUILD_OPT}" build-fip-nonsecure
		build_optee ${OPTEE_DIR} "${OPTEE_BUILD_OPT}" build-singleimage
		# generate fip-nonsecure.img
		gen_third ${TARGET_SOC} ${OPTEE_DIR}/optee_build/result/fip-nonsecure.bin \
			0xbdf00000 0x00000000 ${OPTEE_DIR}/optee_build/result/fip-nonsecure.img
	fi
fi

if [ "${TARGET_SOC}" == "s5p6818" ] && [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_SECURE}" == "true" ]; then
	build_optee ${OPTEE_DIR} "${OPTEE_BUILD_OPT}" all
	# generate fip-loader-emmc.img
	# -m argument decided by partmap.txt
	#    first: fip-secure.img offset
	#    second: fip-nonsecure.img offset
	gen_third ${TARGET_SOC} \
		${OPTEE_DIR}/optee_build/result/fip-loader.bin \
		0xbfcc0000 0xbfd00800 ${OPTEE_DIR}/optee_build/result/fip-loader-emmc.img \
		"-k 3 -m 0x60200 -b 3 -p 2 -m 0x1E0200 -b 3 -p 2"
	# generate fip-loader-sd.img
	gen_third ${TARGET_SOC} \
		${OPTEE_DIR}/optee_build/result/fip-loader.bin \
		0xbfcc0000 0xbfd00800 ${OPTEE_DIR}/optee_build/result/fip-loader-sd.img \
		"-k 3 -m 0x60200 -b 3 -p 0 -m 0x1E0200 -b 3 -p 0"
	# generate fip-secure.img
	gen_third ${TARGET_SOC} ${OPTEE_DIR}/optee_build/result/fip-secure.bin \
		0xbfb00000 0x00000000 ${OPTEE_DIR}/optee_build/result/fip-secure.img
	# generate fip-nonsecure.img
	gen_third ${TARGET_SOC} ${OPTEE_DIR}/optee_build/result/fip-nonsecure.bin \
		0xbdf00000 0x00000000 ${OPTEE_DIR}/optee_build/result/fip-nonsecure.img
	# generate fip-loader-usb.img
	# first -z size : size of fip-secure.img
	# second -z size : size of fip-nonsecure.img
	fip_sec_size=$(stat --printf="%s" ${OPTEE_DIR}/optee_build/result/fip-secure.img)
	fip_nonsec_size=$(stat --printf="%s" ${OPTEE_DIR}/optee_build/result/fip-nonsecure.img)
	gen_third ${TARGET_SOC} \
		${OPTEE_DIR}/optee_build/result/fip-loader.bin \
		0xbfcc0000 0xbfd00800 ${OPTEE_DIR}/optee_build/result/fip-loader-usb.img \
		"-k 0 -u -m 0xbfb00000 -z ${fip_sec_size} -m 0xbdf00000 -z ${fip_nonsec_size}"
	cat ${OPTEE_DIR}/optee_build/result/fip-secure.img >> ${OPTEE_DIR}/optee_build/result/fip-loader-usb.img
	cat ${OPTEE_DIR}/optee_build/result/fip-nonsecure.img >> ${OPTEE_DIR}/optee_build/result/fip-loader-usb.img
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_KERNEL}" == "true" ]; then
	build_kernel ${KERNEL_DIR} ${TARGET_SOC} ${BOARD} s5p6818_avn_ref_nougat_defconfig ${CROSS_COMPILE}
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_MODULE}" == "true" ]; then
	build_module ${KERNEL_DIR} ${TARGET_SOC} ${CROSS_COMPILE}
fi

function get_fsize()
{
	local f=$1
	local align=$2
	local fsize=$(ls -al ${f} | awk '{print $5}')
	fsize=$(((${fsize} + ${align} - 1) / ${align}))
	fsize=$((${fsize} * ${align}))
	echo -n ${fsize}
}

# Android boot.img
# See system/core/mkbootimg/bootimg.h
# /*
# ** +-----------------+
# ** | boot header     | 1 page
# ** +-----------------+
# ** | kernel          | n pages
# ** +-----------------+
# ** | ramdisk         | m pages
# ** +-----------------+
# ** | second stage    | o pages
# ** +-----------------+
# **
# ** n = (kernel_size + page_size - 1) / page_size
# ** m = (ramdisk_size + page_size - 1) / page_size
# ** o = (second_size + page_size - 1) / page_size
# **
# ** 0. all entities are page_size aligned in flash
# ** 1. kernel and ramdisk are required (size != 0)
# ** 2. second is optional (second_size == 0 -> no second)
# ** 3. load each element (kernel, ramdisk, second) at
# **    the specified physical address (kernel_addr, etc)
# ** 4. prepare tags at tag_addr.  kernel_args[] is
# **    appended to the kernel commandline in the tags.
# ** 5. r0 = 0, r1 = MACHINE_TYPE, r2 = tags_addr
# ** 6. if second_size != 0: jump to second_addr
# **    else: jump to kernel_addr
# */
OUT_DIR=${TOP}/out/target/product/avn_ref
DEVICE_DIR=${TOP}/device/nexell/avn_ref
LOAD_ADDR=0x4007f800

BOOT_PARTITION_START_OFFSET=$(grep boot:emmc ${DEVICE_DIR}/partmap_s5p6818.txt | awk -F ':' '{print $4}' | awk -F ',' '{print $1}')
BOOT_PARTITION_START_BLOCK_NUM_HEX=$(printf "0x%x" $((${BOOT_PARTITION_START_OFFSET}/512)))
RECOVERY_PARTITION_START_OFFSET=$(grep recovery:emmc ${DEVICE_DIR}/partmap_s5p6818.txt | awk -F ':' '{print $4}' | awk -F ',' '{print $1}')
RECOVERY_PARTITION_START_BLOCK_NUM_HEX=$(printf "0x%x" $((${RECOVERY_PARTITION_START_OFFSET}/512)))
echo "BOOT_PARTITION_START_OFFSET --> ${BOOT_PARTITION_START_OFFSET}"
echo "BOOT_PARTITION_START_BLOCK_NUM_HEX --> ${BOOT_PARTITION_START_BLOCK_NUM_HEX}"
echo "RECOVERY_BOOT_PARTITION_START_OFFSET --> ${RECOVERY_BOOT_PARTITION_START_OFFSET}"
echo "RECOVERY_BOOT_PARTITION_START_BLOCK_NUM_HEX --> ${RECOVERY_BOOT_PARTITION_START_BLOCK_NUM_HEX}"

# common part
PAGE_SIZE=2048
BOOT_HEADER_SIZE=${PAGE_SIZE}
KERNEL_SIZE=$(get_fsize ${OUT_DIR}/kernel ${PAGE_SIZE})
DTB_SIZE=$(get_fsize ${OUT_DIR}/2ndbootloader ${PAGE_SIZE})
RAMDISK_START_ADDRESS_HEX=$(printf "%x" $((${LOAD_ADDR} + ${BOOT_HEADER_SIZE} + ${KERNEL_SIZE})))
echo "KERNEL_SIZE --> ${KERNEL_SIZE}"
echo "DTB_SIZE --> ${DTB_SIZE}"
echo "RAMDISK_START_ADDRESS_HEX --> ${RAMDISK_START_ADDRESS_HEX}"

# normal boot.img
RAMDISK_SIZE=$(get_fsize ${OUT_DIR}/ramdisk.img ${PAGE_SIZE})
ALL_IMAGE_SIZE=$((${BOOT_HEADER_SIZE} + ${KERNEL_SIZE} + ${RAMDISK_SIZE} + ${DTB_SIZE}))
ALL_IMAGE_BLOCK_COUNT_HEX=$(printf "%x" $((${ALL_IMAGE_SIZE} / 512)))
DTB_START_ADDRESS_HEX=$(printf "%x" $((${LOAD_ADDR} + ${BOOT_HEADER_SIZE} + ${KERNEL_SIZE} + ${RAMDISK_SIZE})))
echo "RAMDISK_SIZE --> ${RAMDISK_SIZE}"
echo "ALL_IMAGE_SIZE --> ${ALL_IMAGE_SIZE}"
echo "ALL_IMAGE_BLOCK_COUNT_HEX --> ${ALL_IMAGE_BLOCK_COUNT_HEX}"
echo "DTB_START_ADDRESS_HEX --> ${DTB_START_ADDRESS_HEX}"

# recovery.img
RECOVERY_RAMDISK_SIZE=$(get_fsize ${OUT_DIR}/ramdisk-recovery.img ${PAGE_SIZE})
RECOVERY_ALL_IMAGE_SIZE=$((${BOOT_HEADER_SIZE} + ${KERNEL_SIZE} + ${RECOVERY_RAMDISK_SIZE} + ${DTB_SIZE}))
RECOVERY_ALL_IMAGE_BLOCK_COUNT_HEX=$(printf "%x" $((${RECOVERY_ALL_IMAGE_SIZE} / 512)))
RECOVERY_DTB_START_ADDRESS_HEX=$(printf "%x" $((${LOAD_ADDR} + ${BOOT_HEADER_SIZE} + ${KERNEL_SIZE} + ${RECOVERY_RAMDISK_SIZE})))
echo "RECOVERY_RAMDISK_SIZE --> ${RECOVERY_RAMDISK_SIZE}"
echo "RECOVERY_ALL_IMAGE_SIZE --> ${RECOVERY_ALL_IMAGE_SIZE}"
echo "RECOVERY_ALL_IMAGE_BLOCK_COUNT_HEX --> ${RECOVERY_ALL_IMAGE_BLOCK_COUNT_HEX}"
echo "RECOVERY_DTB_START_ADDRESS_HEX --> ${RECOVERY_DTB_START_ADDRESS_HEX}"

# u-boot envs
BOOTMCMD="bootm ${LOAD_ADDR} ${RAMDISK_START_ADDRESS_HEX} ${DTB_START_ADDRESS_HEX}"
UBOOT_BOOTCMD="mmc read ${LOAD_ADDR} ${BOOT_PARTITION_START_BLOCK_NUM_HEX} ${ALL_IMAGE_BLOCK_COUNT_HEX}; ${BOOTMCMD}"

RECOVERY_BOOTMCMD="bootm ${LOAD_ADDR} ${RAMDISK_START_ADDRESS_HEX} ${RECOVERY_DTB_START_ADDRESS_HEX}"
UBOOT_RECOVERYBOOT="mmc read ${LOAD_ADDR} ${RECOVERY_PARTITION_START_BLOCK_NUM_HEX} ${RECOVERY_ALL_IMAGE_BLOCK_COUNT_HEX}; ${RECOVERY_BOOTMCMD}"

UBOOT_BOOTARGS="console=ttySAC3,115200n8 loglevel=7 printk.time=1 androidboot.hardware=avn_ref androidboot.console=ttySAC3 androidboot.serialno=0123456789abcdef nx_drm.fb_buffers=3 nx_drm.fb_vblank nx_drm.fb_pan_crtcs=0x1 quiet"
SPLASH_SOURCE="mmc"
SPLASH_OFFSET="0x2e4200"

echo "UBOOT_BOOTCMD ==> ${UBOOT_BOOTCMD}"
echo "UBOOT_RECOVERYBOOT ==> ${UBOOT_RECOVERYBOOT}"

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_UBOOT}" == "true" ]; then
	pushd `pwd`
	cd ${UBOOT_DIR}
	build_uboot_env_param ${CROSS_COMPILE} "${UBOOT_BOOTCMD}" "${UBOOT_BOOTARGS}" "${SPLASH_SOURCE}" "${SPLASH_OFFSET}" "${UBOOT_RECOVERYBOOT}"
	popd
fi

# TODO: get seek offset from configuration file
bl1=${BL1_DIR}/bl1-${TARGET_SOC}/out/bl1-emmcboot.bin
fip_loader=${OPTEE_DIR}/optee_build/result/fip-loader-emmc.img
fip_secure=${OPTEE_DIR}/optee_build/result/fip-secure.img
fip_nonsecure=${OPTEE_DIR}/optee_build/result/fip-nonsecure.img
uboot_param=${UBOOT_DIR}/params.bin
boot_logo=${TOP}/device/nexell/avn_ref/logo.bmp
out_file=${TOP}/device/nexell/avn_ref/bootloader
test -f ${out_file} && rm -f ${out_file}
# 0x2e4000: see below information
#######################################################################
# flash=mmc,0:bl1:2nd:0x200,0x10000:bl1-emmcboot.bin;
# flash=mmc,0:fip-loader:boot:0x10200,0x50000:fip-loader-emmc.img;
# flash=mmc,0:fip-secure:boot:0x60200,0x180000:fip-secure.img;
# flash=mmc,0:fip-nonsecure:boot:0x1E0200,0x100000:fip-nonsecure.img;
# flash=mmc,0:env:env:0x2E0200,0x4000:params.bin;
# flash=mmc,0:logo:boot:0x2E4200,0x200000:logo.bmp
#######################################################################
dd if=/dev/zero of=${out_file} bs=16384 count=185
dd if=${bl1} of=${out_file} bs=1
dd if=${fip_loader} of=${out_file} seek=65536 bs=1
dd if=${fip_secure} of=${out_file} seek=393216 bs=1
dd if=${fip_nonsecure} of=${out_file} seek=1966080 bs=1
dd if=${uboot_param} of=${out_file} seek=3014656 bs=1
dd if=${boot_logo} of=${out_file} seek=3031040 bs=1
sync

cp ${TOP}/device/nexell/avn_ref/bootloader ${TOP}/out/target/product/avn_ref

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_ANDROID}" == "true" ]; then
	generate_key
	build_android ${TARGET_SOC} ${BOARD} ${BUILD_TAG}
fi

if [ "${BUILD_DIST}" == "true" ]; then
	build_dist ${TARGET_SOC} ${BOARD} ${BUILD_TAG}
fi

post_process ${TARGET_SOC} \
	device/nexell/${BOARD}/partmap_s5p6818.txt \
	${RESULT_DIR} \
	${BL1_DIR}/bl1-${TARGET_SOC}/out \
	${OPTEE_DIR}/optee_build/result \
	${UBOOT_DIR} \
	${KERNEL_DIR}/arch/arm64/boot \
	${KERNEL_DIR}/arch/arm64/boot/dts/nexell \
	67108864 \
	${TOP}/out/target/product/${BOARD} \
	avn \
	${TOP}/device/nexell/avn_ref/logo.bmp

make_build_info ${RESULT_DIR}
