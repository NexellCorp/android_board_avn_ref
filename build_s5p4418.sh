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

dev_portnum=2
MEM="2GB"

CROSS_COMPILE=
if [ "${TARGET_SOC}" == "s5p6818" ]; then
	CROSS_COMPILE="aarch64-linux-android-"
	# CROSS_COMPILE32="arm-eabi-"
	CROSS_COMPILE32="arm-linux-gnueabihf-"
else
	CROSS_COMPILE="arm-eabi-"
fi

UBOOT_BOOTCMD="ext4load mmc 0:1 0x40008000 zImage; ext4load mmc 0:1 0x48000000 ramdisk.img; ext4load mmc 0:1 0x49000000 s5p4418-avn_ref-rev00.dtb; bootz 0x40008000 0x48000000 0x49000000"
UBOOT_BOOTARGS="console=ttyAMA3,115200n8 loglevel=7 printk.time=1 androidboot.hardware=avn_ref androidboot.console=ttyAMA3 androidboot.serialno=s5p4418_avn_ref nx_drm.fb_buffers=3 nx_drm.fb_vblank quiet"

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_BL1}" == "true" ]; then
	build_bl1_s5p4418 ${BL1_DIR}/bl1-${TARGET_SOC} s5p4418 avn ${dev_portnum}
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_UBOOT}" == "true" ]; then
	build_uboot ${UBOOT_DIR} ${TARGET_SOC} ${BOARD} ${CROSS_COMPILE}
	pushd `pwd`
	cd ${UBOOT_DIR}
	build_uboot_env_param ${CROSS_COMPILE} "${UBOOT_BOOTCMD}" "${UBOOT_BOOTARGS}"
	popd

	gen_third ${TARGET_SOC} ${UBOOT_DIR}/u-boot.bin \
		0x43c00000 0x43c00000 ${TOP}/device/nexell/secure/bootloader.img
fi

if [ "${TARGET_SOC}" == "s5p4418" ] && [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_SECURE}" == "true" ]; then
	pos=0
	file_size=0

	build_bl2_s5p4418 ${TOP}/device/nexell/secure/bl2-s5p4418
	build_armv7_dispatcher ${TOP}/device/nexell/secure/armv7-dispatcher

	gen_third ${TARGET_SOC} ${TOP}/device/nexell/secure/bl2-s5p4418/out/pyrope-bl2.bin \
		0xb0fe0000 0xb0fe0400 ${TOP}/device/nexell/secure/loader-emmc.img \
		"-m 0x40200 -b 3 -p ${dev_portnum} -m 0x1E0200 -b 3 -p ${dev_portnum} -m 0x60200 -b 3 -p ${dev_portnum}"
	gen_third ${TARGET_SOC} ${TOP}/device/nexell/secure/armv7-dispatcher/out/armv7_dispatcher-raptor.bin \
		0xffff0200 0xffff0200 ${TOP}/device/nexell/secure/bl_mon.img \
		"-m 0x40200 -b 3 -p ${dev_portnum} -m 0x1E0200 -b 3 -p ${dev_portnum} -m 0x60200 -b 3 -p ${dev_portnum}"

	file_size=35840
	dd if=${TOP}/device/nexell/secure/loader-emmc.img of=${TOP}/device/nexell/secure/fip-loader-usb.img seek=0 bs=1
	let pos=pos+file_size
	file_size=28672
	dd if=${TOP}/device/nexell/secure/bl_mon.img of=${TOP}/device/nexell/secure/fip-loader-usb.img seek=${pos} bs=1
	let pos=pos+file_size
	dd if=${TOP}/device/nexell/secure/bootloader.img of=${TOP}/device/nexell/secure/fip-loader-usb.img seek=${pos} bs=1
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_KERNEL}" == "true" ]; then
	build_kernel ${KERNEL_DIR} ${TARGET_SOC} ${BOARD} s5p4418_avn_ref_nougat_defconfig ${CROSS_COMPILE}
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_MODULE}" == "true" ]; then
	build_module ${KERNEL_DIR} ${TARGET_SOC} ${CROSS_COMPILE}
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_ANDROID}" == "true" ]; then
	build_android ${TARGET_SOC} ${BOARD} userdebug
fi

post_process ${TARGET_SOC} \
	device/nexell/${BOARD}/partmap_s5p4418.txt \
	${RESULT_DIR} \
	${BL1_DIR}/bl1-${TARGET_SOC}/out \
	${TOP}/device/nexell/secure \
	${UBOOT_DIR} \
	${KERNEL_DIR}/arch/arm/boot \
	${KERNEL_DIR}/arch/arm/boot/dts \
	33554432 \
	${TOP}/out/target/product/${BOARD} \
	avn

address=0x93c00000
if [ "${MEM}" == "2GB" ]; then
	address=0x63c00000
elif [ "${MEM}" == "1GB" ]; then
	address=0x83c00000
fi
gen_boot_usb_script_4418 slsiap ${address} ${RESULT_DIR}

make_build_info ${RESULT_DIR}
