#!/bin/bash

set -e

CROSS_COMPILE="aarch64-linux-android-"
CROSS_COMPILE32="arm-linux-gnueabihf-"

OPTEE_BUILD_OPT="PLAT_DRAM_SIZE=2048 PLAT_UART_BASE=0xc00a3000 SECURE_ON=0 SUPPORT_ANDROID=1"
OPTEE_BUILD_OPT+=" CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE32=${CROSS_COMPILE32}"
OPTEE_BUILD_OPT+=" UBOOT_DIR=${UBOOT_DIR}"
if [ "${QUICKBOOT}" == "true" ]; then
OPTEE_BUILD_OPT+=" QUICKBOOT=1"
fi

KERNEL_IMG=${KERNEL_DIR}/arch/arm64/boot/Image
DTB_IMG=${KERNEL_DIR}/arch/arm64/boot/dts/nexell/s5p6818-avn-ref-rev01.dtb

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_BL1}" == "true" ]; then
	build_bl1 ${BL1_DIR}/bl1-${TARGET_SOC} avn 2
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_UBOOT}" == "true" ]; then
	build_uboot ${UBOOT_DIR} ${TARGET_SOC} ${BOARD_NAME} ${CROSS_COMPILE}

	if [ "${BUILD_UBOOT}" == "true" ]; then
		build_optee ${OPTEE_DIR} "${OPTEE_BUILD_OPT}" build-fip-nonsecure
		build_optee ${OPTEE_DIR} "${OPTEE_BUILD_OPT}" build-singleimage
		# generate fip-nonsecure.img
		gen_third ${TARGET_SOC} ${OPTEE_DIR}/optee_build/result/fip-nonsecure.bin \
			0xbdf00000 0x00000000 ${OPTEE_DIR}/optee_build/result/fip-nonsecure.img
	fi
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_SECURE}" == "true" ]; then
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
	build_kernel ${KERNEL_DIR} ${TARGET_SOC} ${BOARD_NAME} s5p6818_avn_ref_nougat_defconfig ${CROSS_COMPILE}
	test -d ${OUT_DIR} && \
		cp ${KERNEL_IMG} ${OUT_DIR}/kernel && \
		cp ${DTB_IMG} ${OUT_DIR}/2ndbootloader
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_MODULE}" == "true" ]; then
	build_module ${KERNEL_DIR} ${TARGET_SOC} ${CROSS_COMPILE}
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_ANDROID}" == "true" ]; then
	rm -rf ${OUT_DIR}/system
	rm -rf ${OUT_DIR}/root
	rm -rf ${OUT_DIR}/data
	generate_key ${BOARD_NAME}
	test -f ${DEVICE_DIR}/domain.te && cp ${DEVICE_DIR}/domain.te ${TOP}/system/sepolicy
	test -f ${DEVICE_DIR}/app.te && cp ${DEVICE_DIR}/app.te ${TOP}/system/sepolicy
	build_android ${TARGET_SOC} ${BOARD_NAME} ${BUILD_TAG}
fi

# u-boot envs
echo "make u-boot env"
if [ -f ${UBOOT_DIR}/u-boot.bin ]; then
	test -f ${UBOOT_DIR}/u-boot.bin && \
		UBOOT_BOOTCMD=$(make_uboot_bootcmd \
		${DEVICE_DIR}/partmap.txt \
		0x4007f800 \
		2048 \
		${KERNEL_IMG} \
		${DTB_IMG} \
		${OUT_DIR}/ramdisk.img \
		"boot:emmc")

	UBOOT_RECOVERYCMD="ext4load mmc 0:6 0x49000000 recovery.dtb; ext4load mmc 0:6 0x40080000 recovery.kernel; ext4load mmc 0:6 0x48000000 ramdisk-recovery.img; booti 40080000 0x48000000:2d0f8f 0x49000000"

	UBOOT_BOOTARGS="console=ttySAC3,115200n8 loglevel=7 printk.time=1 androidboot.hardware=avn_ref androidboot.console=ttySAC3 androidboot.serialno=0123456789abcdef quiet"

	SPLASH_SOURCE="mmc"
	SPLASH_OFFSET="0x2e4200"

	echo "UBOOT_BOOTCMD ==> ${UBOOT_BOOTCMD}"
	echo "UBOOT_RECOVERYCMD ==> ${UBOOT_RECOVERYCMD}"

	pushd `pwd`
	cd ${UBOOT_DIR}
	build_uboot_env_param ${CROSS_COMPILE} "${UBOOT_BOOTCMD}" "${UBOOT_BOOTARGS}" "${SPLASH_SOURCE}" "${SPLASH_OFFSET}" "${UBOOT_RECOVERYCMD}"
	popd
fi

# make bootloader
echo "make bootloader"
# TODO: get seek offset from configuration file
bl1=${BL1_DIR}/bl1-${TARGET_SOC}/out/bl1-emmcboot.bin
loader=${OPTEE_DIR}/optee_build/result/fip-loader-emmc.img
secure=${OPTEE_DIR}/optee_build/result/fip-secure.img
nonsecure=${OPTEE_DIR}/optee_build/result/fip-nonsecure.img
param=${UBOOT_DIR}/params.bin
boot_logo=${DEVICE_DIR}/logo.bmp
out_file=${DEVICE_DIR}/bootloader

if [ -f ${bl1} ] && [ -f ${loader} ] && [ -f ${secure} ] && [ -f ${nonsecure} ] && [ -f ${param} ] && [ -f ${boot_logo} ]; then
	BOOTLOADER_PARTITION_SIZE=$(get_partition_size ${DEVICE_DIR}/partmap.txt bootloader)
	make_bootloader \
		${BOOTLOADER_PARTITION_SIZE} \
		${bl1} \
		65536 \
		${loader} \
		393216 \
		${secure} \
		1966080 \
		${nonsecure} \
		3014656 \
		${param} \
		3031040 \
		${boot_logo} \
		${out_file}

	test -d ${OUT_DIR} && cp ${DEVICE_DIR}/bootloader ${OUT_DIR}
fi

if [ "${BUILD_DIST}" == "true" ]; then
	build_dist ${TARGET_SOC} ${BOARD_NAME} ${BUILD_TAG}
fi

if [ "${BUILD_KERNEL}" == "true" ]; then
	test -f ${OUT_DIR}/ramdisk.img && \
		make_android_bootimg \
			${KERNEL_IMG} \
			${DTB_IMG} \
			${OUT_DIR}/ramdisk.img \
			${OUT_DIR}/boot.img \
			2048 \
			"buildvariant=${BUILD_TAG}"
fi

post_process ${TARGET_SOC} \
	${DEVICE_DIR}/partmap.txt \
	${RESULT_DIR} \
	${BL1_DIR}/bl1-${TARGET_SOC}/out \
	${OPTEE_DIR}/optee_build/result \
	${UBOOT_DIR} \
	${KERNEL_DIR}/arch/arm64/boot \
	${KERNEL_DIR}/arch/arm64/boot/dts/nexell \
	67108864 \
	${OUT_DIR} \
	avn \
	${DEVICE_DIR}/logo.bmp

make_ext4_recovery_image \
	${KERNEL_IMG} \
	${DTB_IMG} \
	${OUT_DIR}/ramdisk-recovery.img \
	67108864 \
	${RESULT_DIR}

make_build_info ${RESULT_DIR}
