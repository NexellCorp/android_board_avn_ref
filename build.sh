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
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_UBOOT}" == "true" ]; then
	build_uboot ${UBOOT_DIR} ${TARGET_SOC} ${BOARD} ${CROSS_COMPILE}
	if [ "${BUILD_UBOOT}" == "true" ]; then
		build_optee device/nexell/secure "${OPTEE_BUILD_OPT}" build-singleimage
	fi
fi

if [ "${TARGET_SOC}" == "s5p6818" ] && [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_SECURE}" == "true" ]; then
	build_optee ${OPTEE_DIR} "${OPTEE_BUILD_OPT}" all
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_KERNEL}" == "true" ]; then
	build_kernel ${KERNEL_DIR} ${TARGET_SOC} ${BOARD} s5p6818_avn_ref_nougat_defconfig ${CROSS_COMPILE}
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_ANDROID}" == "true" ]; then
	build_android ${TARGET_SOC} ${BOARD} userdebug
fi
