#
# Copyright (C) 2015 The Android Open-Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Inherit the full_base and device configurations
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, device/nexell/avn_ref/aosp_avn_ref_common.mk)

PRODUCT_COPY_FILES += \
		device/nexell/avn_ref/init.avn_ref_64.rc:root/init.avn_ref.rc \
		device/nexell/avn_ref/init.recovery.avn_ref.rc:root/init.recovery.avn_ref.rc

PRODUCT_COPY_FILES += \
		device/nexell/kernel/kernel-4.4.x/arch/arm64/boot/Image:kernel

PRODUCT_COPY_FILES += \
		device/nexell/avn_ref/bootloader:bootloader

PRODUCT_COPY_FILES += \
		device/nexell/kernel/kernel-4.4.x/arch/arm64/boot/dts/nexell/s5p6818-avn-ref-rev01.dtb:2ndbootloader

PRODUCT_COPY_FILES += \
	device/nexell/avn_ref/fstab.avn_ref:root/fstab.avn_ref
