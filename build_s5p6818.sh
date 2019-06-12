#!/bin/bash

set -e

DEVID_USB=0
DEVID_SPI=1
DEVID_NAND=2
DEVID_SDMMC=3
DEVID_SDFS=4
DEVID_UART=5
PORT_EMMC=0
PORT_SD=2
DEVIDS=("usb" "spi" "nand" "sdmmc" "sdfs" "uart")
PORTS=("emmc" "sd")

RSA_SIGN_TOOL=${DEVICE_DIR}/tools/rsa_sign_pss
SECURE_TOOL=${TOP}/device/nexell/tools/SECURE_BINGEN

BL1_SOURCE=${TOP}/device/nexell/bl1/bl1-s5p6818
OPTEE_BUILD=${TOP}/device/nexell/secure/optee_build

FIP_SEC_SIZE=
FIP_NONSEC_SIZE=

if [ "${RSA_KEY}" == "none" ]; then
	RSA_KEY=${DEVICE_DIR}/private_key.pem
fi

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

# secure common
function gen_hash_rsa()
{
	local in_img=${1}
	local hash_name=${2}
	local private_key=${3}

	# generate hash ... skip
	#openssl dgst -sha256 -binary -out ${hash_name} ${in_img}

	# generate sig, pub
	#echo "private key: ${private_key}"
	#echo "src: ${in_img}"
	${RSA_SIGN_TOOL} ${private_key} ${in_img}

	# <output>
	#     ${in_img}.sig
	#     ${in_img}.pub
}

#write_hash_rsa ${gen_img} ${in_img}.pub ${in_img}.sig
function write_hash_rsa()
{
	img=${1}
	pub=${2}
	sig=${3}

	dd if=${pub} of=${img} conv=notrunc ibs=256 count=1 obs=256 seek=2
	dd if=${sig} of=${img} conv=notrunc ibs=256 count=1 obs=256 seek=3
}

function aes_encrypt()
{
	local pad_opt=
	local filesize=
	local out_img=${1}
	local in_img=${2}
	local aes_key=${3}

	echo "encrypt with key ${aes_key} ............."

	if [ ! -f ${aes_key} ]; then
		echo "${aes_key} not found!"
		exit 1
	fi

	in_img=`readlink -e ${in_img}`
	echo "in_img:${in_img}"

	filesize=`stat --printf="%s" ${in_img}`
	#echo "filesize:${filesize}"

	if [ `expr $(( ($filesize & (16-1)) ))` == 0 ]; then
		pad_opt="-nopad"
	fi

	openssl enc -aes-128-ecb -e \
            -in ${in_img} \
            -out ${out_img} -p -nosalt \
	    ${pad_opt} \
            -K  `cat ${aes_key}`

	echo "[AES] ENC DONE:${out_img}"
}

function make_2ndboot_enc()
{
	local result_dir=${1}
	local aes_key=${2}
	local src_file=${3}
	local target_file=${4}

	local bl1_source=${BL1_SOURCE}
	local gen_img=${src_file}
	local aes_in_img=${gen_img}
	local aes_out_img=${target_file}

	pushd ${result_dir}
	# RSA public key generate and override
	gen_hash_rsa ${gen_img} "" ${RSA_KEY}
	dd if=${gen_img}.pub of=${gen_img} ibs=256 count=1 obs=512 seek=1 conv=notrunc

	# AES encrypt with HW Root Key or Default Zero Key.
	aes_encrypt ${aes_out_img} ${aes_in_img} ${aes_key}
	popd
}

# fip-loader.bin
function gen_loader()
{
	local result_dir=${1}
	local chip_name=$(echo -n ${TARGET_SOC} | awk '{print toupper($0)}')

	local in_img=${2}
	local out_img=
	local gen_img="${in_img}".gen
	local aes_in_img="${gen_img}"
	local aes_out_img=
	local devname=

	local hash_name="${in_img}".hash
	local private_key=${3}
	local aes_key=${4}

	local load_addr=0x7fcc0000
	local jump_addr=0x7fd00800
	local bootdev=${5}
	local portnum=${6}

	if [ ! -f ${result_dir}/${in_img} ]; then
		echo "Error in gen_loader(): ${in_img} not found!"
		exit 1
	fi

	if [ ! -f ${private_key} ]; then
		echo "Error in gen_loader(): private key '${private_key}' not found!"
		exit 1
	fi

	if [ -z ${load_addr} ] || [ -z ${jump_addr} ]; then
		echo "Error in gen_loader(): Enter load/jump address."
		exit 1
	fi

	# parsing bootdev, portnum
	if [ -z ${bootdev} ]; then
		bootdev=${DEVID_SDMMC}
	fi

	if [ -z ${portnum} ]; then
		portnum=${PORT_EMMC}
	fi

	devname=${DEVIDS[${bootdev}]}
	if [ ${bootdev} == ${DEVID_SDMMC} ]; then
		if [ ${portnum} == ${PORT_EMMC} ]; then
			devname="emmc"
		else
			devname="sd"
		fi

		# 0x60200 : MBR (0x200) + 2ndboot (0x10000) + FIP-LOADER size (0x50000)
		# 0x1E0200 : 0x50200 + FIP-SECURE size(0x180000)
		dev_offset_opts="-m 0x60200 -b ${bootdev} -p ${portnum} \
			-m 0x1E0200 -b ${bootdev} -p ${portnum}"
	elif [ ${bootdev} == ${DEVID_USB} ]; then
		dev_offset_opts="-u -m 0x7fb00000 -z ${FIP_SEC_SIZE} \
			-m 0x7df00000 -z ${FIP_NONSEC_SIZE}"
	fi
	out_img="fip-loader-${devname}.img"
	aes_out_img="${out_img}"
	echo "[fip-loader] bootdev: ${bootdev}"
	echo "[fip-loader] out_img: ${out_img}"

	# BINGEN
	${SECURE_TOOL} -c ${chip_name} -t 3rdboot \
		-i ${result_dir}/${in_img} \
		-o ${result_dir}/${gen_img} \
		-l ${load_addr} -e ${jump_addr} \
		-k ${bootdev} \
		${dev_offset_opts}

	pushd ${result_dir}
	if [ "${ENABLE_ENC}" == "true" ]; then
		# RSA public key generate and override
		gen_hash_rsa ${gen_img} "" ${private_key}
		dd if=${gen_img}.pub of=${gen_img} ibs=256 count=1 obs=512 seek=1 conv=notrunc
	fi
	rm -f ${aes_out_img}
	if [ "${aes_out_img}" == "fip-loader-usb.img" ]; then
		cp ${aes_in_img} fip-loader-usb.bin
	fi
	# AES encrypt with HW Root Key or Default Zero Key.
	aes_encrypt ${aes_out_img} ${aes_in_img} ${aes_key}
	popd
}

function gen_loader_emmc()
{
	echo "gen_loader_emmc"
	echo "gen_loader ${1} ${2} ${3} ${4} ${DEVID_SDMMC} ${PORT_EMMC} ${5} ${6} ${7}"
	gen_loader ${1} ${2} ${3} ${4} ${DEVID_SDMMC} ${PORT_EMMC} ${5} ${6} ${7}
}

function gen_loader_sd()
{
	echo "gen_loader_sd"
	echo "gen_loader ${1} ${2} ${3} ${4} ${DEVID_SDMMC} ${PORT_SD} ${5} ${6} ${7}"
	gen_loader ${1} ${2} ${3} ${4} ${DEVID_SDMMC} ${PORT_SD} ${5} ${6} ${7}
}

function gen_loader_usb()
{
	echo "gen_loader_usb"
	echo "gen_loader ${1} ${2} ${3} ${4} ${DEVID_USB}"
	gen_loader ${1} ${2} ${3} ${4} ${DEVID_USB}

	pushd ${RESULT_DIR}
	cat fip-secure.img >> fip-loader-usb.img
	cat fip-nonsecure.img >> fip-loader-usb.img
	popd
}

# fip-secure.bin
function gen_secure()
{
	local result_dir=${1}
	local chip_name=$(echo -n ${TARGET_SOC} | awk '{print toupper($0)}')

	local in_img=${2}
	local out_img=fip-secure.img
	local gen_img="${in_img}".gen

	local hash_name="${in_img}".hash
	local private_key=${3}

	local load_addr=0x7fb00000
	local jump_addr=0x00000000

	if [ ! -f ${result_dir}/${in_img} ]; then
		echo "Error in gen_secure(): ${in_img} not found!"
		exit 1
	fi

	if [ ! -f ${private_key} ]; then
		echo "Error in gen_secure(): private key '${private_key}' not found!"
		exit 1
	fi

	if [ -z ${load_addr} ] || [ -z ${jump_addr} ]; then
		echo "Error in gen_secure(): Enter load/jump address."
		exit 1
	fi

	# BINGEN
	${SECURE_TOOL} -c ${chip_name} -t 3rdboot \
		-i ${result_dir}/${in_img} \
		-o ${result_dir}/${gen_img} \
		-l ${load_addr} -e ${jump_addr}

	pushd ${result_dir}

	# RSA
	gen_hash_rsa ${in_img} ${hash_name} ${private_key}

	write_hash_rsa ${gen_img} /dev/null ${in_img}.sig
	cp ${gen_img} ${out_img}

	FIP_SEC_SIZE=`stat --printf="%s" ${out_img}`
	popd
}

# fip-nonsecure.bin
function gen_nonsecure()
{
	local result_dir=${1}
	local chip_name=$(echo -n ${TARGET_SOC} | awk '{print toupper($0)}')

	local in_img=${2}
	local out_img=fip-nonsecure.img
	local gen_img="${in_img}".gen

	local hash_name="${in_img}".hash
	local private_key=${3}

	local load_addr=0x7df00000
	local jump_addr=0x00000000

	if [ ! -f ${result_dir}/${in_img} ]; then
		echo "Error in gen_nonsecure(): ${in_img} not found!"
		exit 1
	fi

	if [ ! -f ${private_key} ]; then
		echo "Error in gen_nonsecure(): private key '${private_key}' not found!"
		exit 1
	fi

	if [ -z ${load_addr} ] || [ -z ${jump_addr} ]; then
		echo "Error in gen_nonsecure(): Enter load/jump address."
		exit 1
	fi

	# BINGEN
	${SECURE_TOOL} -c ${chip_name} -t 3rdboot \
		-i ${result_dir}/${in_img} \
		-o ${result_dir}/${gen_img} \
		-l ${load_addr} -e ${jump_addr}

	pushd ${result_dir}
	if [ ${ENABLE_ENC} == "true" ]; then
		# RSA
		gen_hash_rsa ${in_img} ${hash_name} ${private_key}

		write_hash_rsa ${gen_img} /dev/null ${in_img}.sig
	fi
	cp ${gen_img} ${out_img}

	FIP_NONSEC_SIZE=`stat --printf="%s" ${out_img}`
	popd
}

function post_process_secure()
{
	print_build_info post_process_secure

	local result_dir=${RESULT_DIR}
	mkdir -p ${result_dir}

	local rsa_sign_tool=$(readlink -e ${RSA_SIGN_TOOL})
	local private_key=$(readlink -e ${RSA_KEY})

	local bl1_source=${BL1_SOURCE}
	local optee_build=${OPTEE_BUILD}

	if [ "${AES_KEY}" != "none" ]; then
		cp ${bl1_source}/out/bl1-*.bin* ${result_dir}

		cp -a ${optee_build}/result/* ${result_dir}

		local aes_key=$(readlink -e ${AES_KEY})

		make_2ndboot_enc ${result_dir} ${aes_key} bl1-sdboot.bin bl1-sdboot.img
		make_2ndboot_enc ${result_dir} ${aes_key} bl1-emmcboot.bin bl1-emmcboot.img
		make_2ndboot_enc ${result_dir} ${aes_key} bl1-avn.bin bl1-usbboot.img

		gen_loader_emmc ${result_dir} fip-loader.bin ${private_key} ${aes_key}
		gen_loader_sd ${result_dir} fip-loader.bin ${private_key} ${aes_key}
		gen_secure ${result_dir} fip-secure.bin ${private_key}
	fi

	gen_nonsecure ${result_dir} fip-nonsecure.bin ${private_key}

	if [ "${AES_KEY}" != "none" ]; then
		gen_loader_usb ${result_dir} fip-loader.bin ${private_key} ${aes_key}
	fi

	print_build_done
}

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_BL1}" == "true" ]; then
	build_bl1 ${BL1_DIR}/bl1-${TARGET_SOC} avn 2 emmc
	build_bl1 ${BL1_DIR}/bl1-${TARGET_SOC} avn 0 sd no
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_UBOOT}" == "true" ]; then
	build_uboot ${UBOOT_DIR} ${TARGET_SOC} ${BOARD_NAME} ${CROSS_COMPILE}

	if [ "${BUILD_UBOOT}" == "true" ]; then
		build_optee ${OPTEE_DIR} "${OPTEE_BUILD_OPT}" build-fip-nonsecure
		build_optee ${OPTEE_DIR} "${OPTEE_BUILD_OPT}" build-singleimage
		if [ "${ENABLE_ENC}" == "false" ]; then
			# generate fip-nonsecure.img
			gen_third ${TARGET_SOC} ${OPTEE_DIR}/optee_build/result/fip-nonsecure.bin \
				0xbdf00000 0x00000000 ${OPTEE_DIR}/optee_build/result/fip-nonsecure.img
		fi
	fi
fi

if [ "${BUILD_ALL}" == "true" ] || [ "${BUILD_SECURE}" == "true" ]; then
	build_optee ${OPTEE_DIR} "${OPTEE_BUILD_OPT}" all

	if [ "${ENABLE_ENC}" == "false" ]; then
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
	build_android ${TARGET_SOC} ${BOARD_NAME} ${BUILD_TAG}
fi

# u-boot envs
echo "make u-boot env"
if [ -f ${UBOOT_DIR}/u-boot.bin ]; then
	UBOOT_BOOTCMD=$(make_uboot_bootcmd_dtimg \
        ${DEVICE_DIR}/partmap.txt \
        0x4007f800 \
        2048 \
        ${KERNEL_IMG} \
		0x49000000 \
        ${OUT_DIR}/ramdisk.img \
        "boot:emmc")

	UBOOT_RECOVERYCMD="ext4load mmc 0:7 0x49000000 recovery.dtb; ext4load mmc 0:7 0x40080000 recovery.kernel; ext4load mmc 0:7 0x48000000 ramdisk-recovery.img; booti 40080000 0x48000000:2d0f8f 0x49000000"

	UBOOT_BOOTARGS="console=ttySAC3,115200n8 loglevel=7 printk.time=1 androidboot.hardware=avn_ref androidboot.console=ttySAC3 androidboot.serialno=0123456789abcdef quiet"

	SPLASH_SOURCE="mmc"
	SPLASH_OFFSET="0x2e4200"

	AUTORECOVERY_CMD="nxrecovery mmc 1 mmc 0"

	echo "UBOOT_BOOTCMD ==> ${UBOOT_BOOTCMD}"
	echo "UBOOT_RECOVERYCMD ==> ${UBOOT_RECOVERYCMD}"

	pushd `pwd`
	cd ${UBOOT_DIR}
	build_uboot_env_param ${CROSS_COMPILE} "${UBOOT_BOOTCMD}" "${UBOOT_BOOTARGS}" "${SPLASH_SOURCE}" "${SPLASH_OFFSET}" "${UBOOT_RECOVERYCMD}"
	# for sd card auto recovery
	build_uboot_env_param ${CROSS_COMPILE} "${UBOOT_BOOTCMD}" "${UBOOT_BOOTARGS}" "${SPLASH_SOURCE}" "${SPLASH_OFFSET}" "${UBOOT_RECOVERYCMD}" "${AUTORECOVERY_CMD}" "params_sd.bin"
	popd
fi

if [ "${ENABLE_ENC}" == "true" ]; then
	post_process_secure
fi

# make bootloader
bl1=""
loader=""
secure=""
nonsecure=""

echo "make bootloader for emmc"
# TODO: get seek offset from configuration file

if [ "${ENABLE_ENC}" == "true" ]; then
	bl1=${RESULT_DIR}/bl1-emmcboot.img
	loader=${RESULT_DIR}/fip-loader-emmc.img
	secure=${RESULT_DIR}/fip-secure.img
	nonsecure=${RESULT_DIR}/fip-nonsecure.img
else
	bl1=${BL1_DIR}/bl1-${TARGET_SOC}/out/bl1-emmcboot.bin
	loader=${OPTEE_DIR}/optee_build/result/fip-loader-emmc.img
	secure=${OPTEE_DIR}/optee_build/result/fip-secure.img
	nonsecure=${OPTEE_DIR}/optee_build/result/fip-nonsecure.img
fi

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


echo "make bootloader for sd"

if [ "${ENABLE_ENC}" == "true" ]; then
	bl1=${RESULT_DIR}/bl1-sdboot.img
	loader=${RESULT_DIR}/fip-loader-sd.img
else
	bl1=${BL1_DIR}/bl1-${TARGET_SOC}/out/bl1-sdboot.bin
	loader=${OPTEE_DIR}/optee_build/result/fip-loader-sd.img
fi
param=${UBOOT_DIR}/params_sd.bin
out_file=${DEVICE_DIR}/bootloader-sd

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

	test -d ${OUT_DIR} && cp ${DEVICE_DIR}/bootloader-sd ${OUT_DIR}
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


cp -f ${OUT_DIR}/dtb.img ${RESULT_DIR}

make_build_info ${RESULT_DIR}
