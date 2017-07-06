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

OPTEE_BUILD_OPT="PLAT_DRAM_SIZE=2048 PLAT_UART_BASE=0xc00a3000 SECURE_ON=0"
OPTEE_BUILD_OPT+=" CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE32=${CROSS_COMPILE32}"
OPTEE_BUILD_OPT+=" UBOOT_DIR=${UBOOT_DIR}"

UBOOT_BOOTCMD="ext4load mmc 0:1 0x40080000 Image; ext4load mmc 0:1 0x48000000 ramdisk.img; ext4load mmc 0:1 0x49000000 s5p6818-avn-ref-rev01.dtb; booti 0x40080000 0x48000000 0x49000000"
UBOOT_BOOTARGS="console=ttySAC3,115200n8 loglevel=7 printk.time=1 androidboot.hardware=avn_ref androidboot.console=ttySAC3 androidboot.serialno=0123456789abcdef nx_drm.fb_buffers=3 nx_drm.fb_vblank nx_drm.fb_pan_crtcs=0x1 quiet"

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
	pushd `pwd`
	cd ${UBOOT_DIR}
	build_uboot_env_param ${CROSS_COMPILE} "${UBOOT_BOOTCMD}" "${UBOOT_BOOTARGS}"
	popd

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

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_ANDROID}" == "true" ]; then
	generate_key
	build_android ${TARGET_SOC} ${BOARD} ${BUILD_TAG}
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
