#!/bin/bash

set -e

TOP=`pwd`
#export TOP

source ${TOP}/device/nexell/tools/common.sh
source ${TOP}/device/nexell/tools/dir.sh
source ${TOP}/device/nexell/tools/make_build_info.sh

TARGET_SOC=$2
BOARD=$(get_board_name $0)

parse_args -b ${BOARD} $@
print_args

if [ "${TARGET_SOC}" == "s5p6818" ]; then
	cp ./device/nexell/${BOARD}/TargetArm64Config.mk ./device/nexell/${BOARD}/BoardConfig.mk
	cp ./device/nexell/${BOARD}/aosp_avn_ref_64.mk ./device/nexell/${BOARD}/aosp_avn_ref.mk
	./device/nexell/${BOARD}/build_s5p6818.sh $@
else
	cp ./device/nexell/${BOARD}/TargetArmConfig.mk ./device/nexell/${BOARD}/BoardConfig.mk
	cp ./device/nexell/${BOARD}/aosp_avn_ref_32.mk ./device/nexell/${BOARD}/aosp_avn_ref.mk
	./device/nexell/${BOARD}/build_s5p4418.sh $@
fi

exit
