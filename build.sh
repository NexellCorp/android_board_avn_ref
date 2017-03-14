#!/bin/bash

set -e

TOP=`pwd`
export TOP

source ${TOP}/device/nexell/tools/common.sh
source ${TOP}/device/nexell/tools/dir.sh

BOARD=$(get_board_name $0)

parse_args -b ${BOARD} $@
print_args
setup_toolchain
export_work_dir
patches

CROSS_COMPILE=
if [ "${TARGET_SOC}" == "s5p6818" ]; then
	CROSS_COMPILE="aarch64-linux-android-"
	# CROSS_COMPILE32="arm-eabi-"
	CROSS_COMPILE32="arm-linux-gnueabihf-"
else
	CROSS_COMPILE="arm-eabi-"
fi

OPTEE_BUILD_OPT="PLAT_DRAM_SIZE=1024 PLAT_UART_BASE=0xc00a3000 SECURE_ON=0"
OPTEE_BUILD_OPT+=" CROSS_COMPILE=${CROSS_COMPILE} CROSS_COMPILE32=${CROSS_COMPILE32}"
OPTEE_BUILD_OPT+=" UBOOT_DIR=${UBOOT_DIR}"

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_BL1}" == "true" ]; then
	# TODO: after bl1 revision, apply real boardname to second arg
	build_bl1 ${BL1_DIR}/bl1-${TARGET_SOC} AVN
	gen_bl1 ${TARGET_SOC} ${BL1_DIR}/bl1-${TARGET_SOC}/out/bl1-avn.bin \
		device/nexell/avn_ref/nsih_avn_ref_usb.txt \
		${BL1_DIR}/bl1-${TARGET_SOC}/out/bl1-usbboot.img
	gen_bl1 ${TARGET_SOC} ${BL1_DIR}/bl1-${TARGET_SOC}/out/bl1-avn.bin \
		device/nexell/avn_ref/nsih_avn_ref_emmc.txt \
		${BL1_DIR}/bl1-${TARGET_SOC}/out/bl1-emmcboot.img
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_UBOOT}" == "true" ]; then
	build_uboot ${UBOOT_DIR} ${TARGET_SOC} ${BOARD} ${CROSS_COMPILE}
	if [ "${BUILD_UBOOT}" == "true" ]; then
		build_optee ${OPTEE_DIR} "${OPTEE_BUILD_OPT}" build-fip-nonsecure
		build_optee ${OPTEE_DIR} "${OPTEE_BUILD_OPT}" build-singleimage
		# generate fip-nonsecure.img
		gen_third ${TARGET_SOC} ${OPTEE_DIR}/optee_build/result/fip-nonsecure.bin \
			device/nexell/avn_ref/nsih_avn_ref_emmc.txt \
			0x7df00000 0x00000000 ${OPTEE_DIR}/optee_build/result/fip-nonsecure.img
	fi
fi

if [ "${TARGET_SOC}" == "s5p6818" ] && [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_SECURE}" == "true" ]; then
	build_optee ${OPTEE_DIR} "${OPTEE_BUILD_OPT}" all
	# generate fip-loader.img
	gen_third ${TARGET_SOC} ${OPTEE_DIR}/optee_build/result/fip-loader.bin \
		device/nexell/avn_ref/nsih_avn_ref_emmc.txt \
		0x7fcc0000 0x7fd00800 ${OPTEE_DIR}/optee_build/result/fip-loader.img \
		"-k 3 -m 0x60200 -b 3 -p 2 -m 0x1E0200 -b 3 -p 2"
	# generate fip-secure.img
	gen_third ${TARGET_SOC} ${OPTEE_DIR}/optee_build/result/fip-secure.bin \
		device/nexell/avn_ref/nsih_avn_ref_emmc.txt \
		0x7fb00000 0x00000000 ${OPTEE_DIR}/optee_build/result/fip-secure.img
	# generate fip-nonsecure.img
	gen_third ${TARGET_SOC} ${OPTEE_DIR}/optee_build/result/fip-nonsecure.bin \
		device/nexell/avn_ref/nsih_avn_ref_emmc.txt \
		0x7df00000 0x00000000 ${OPTEE_DIR}/optee_build/result/fip-nonsecure.img
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_KERNEL}" == "true" ]; then
	build_kernel ${KERNEL_DIR} ${TARGET_SOC} ${BOARD} s5p6818_avn_ref_nougat_defconfig ${CROSS_COMPILE}
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_ANDROID}" == "true" ]; then
	build_android ${TARGET_SOC} ${BOARD} userdebug
fi

post_process ${TARGET_SOC} \
	device/nexell/${BOARD}/partmap.txt \
	${RESULT_DIR} \
	${BL1_DIR}/bl1-${TARGET_SOC}/out \
	${OPTEE_DIR}/optee_build/result \
	${UBOOT_DIR} \
	${KERNEL_DIR}/arch/arm64/boot \
	${KERNEL_DIR}/arch/arm64/boot/dts/nexell \
	33554432 \
	${TOP}/out/target/product/${BOARD}
