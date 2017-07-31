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
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)

PRODUCT_NAME := aosp_avn_ref
PRODUCT_DEVICE := avn_ref
PRODUCT_BRAND := Android
PRODUCT_MODEL := AOSP on avn_ref
PRODUCT_MANUFACTURER := NEXELL

PRODUCT_COPY_FILES += \
	device/nexell/avn_ref/fstab.avn_ref:root/fstab.avn_ref

PRODUCT_COPY_FILES += \
	device/nexell/avn_ref/init.recovery.avn_ref.rc:root/init.recovery.avn_ref.rc

PRODUCT_PROPERTY_OVERRIDES += \
	ro.product.first_api_level=21

# Disable bluetooth because avn_ref does not use bluetooth source
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += config.disable_bluetooth=true

# Disable other feature no needed in avn board
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += config.disable_serial=true
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += config.disable_samplingprof=true
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += config.disable_consumerir=true
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += config.disable_rtt=true
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += config.disable_vrmanager=true

$(call inherit-product, device/nexell/avn_ref/device.mk)

PRODUCT_PACKAGES += \
	Launcher3
