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
ifeq ($(TARGET_SOC),s5p6818)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
endif
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)

# Set custom settings
DEVICE_PACKAGE_OVERLAYS := device/nexell/avn_ref/overlay

# Build and run only ART
PRODUCT_RUNTIMES := runtime_libart_default

# Overrides
PRODUCT_NAME := aosp_avn_ref
PRODUCT_DEVICE := avn_ref
PRODUCT_BRAND := Android
PRODUCT_MODEL := AOSP on s5p6818 avn_ref
PRODUCT_MANUFACTURER := NEXELL

# Add openssh support for remote debugging and job submission
PRODUCT_PACKAGES += ssh sftp scp sshd ssh-keygen sshd_config start-ssh uim

# Add wifi-related packages
PRODUCT_PACKAGES += libwpa_client wpa_supplicant hostapd wificond wifilogd
PRODUCT_PROPERTY_OVERRIDES += wifi.interface=wlan0 \
                              wifi.supplicant_scan_interval=15

# Include Launcher3 explicitly
PRODUCT_PACKAGES += Launcher3

# Build default bluetooth a2dp and usb audio HALs
PRODUCT_PACKAGES += \
	audio.a2dp.default \
	audio.usb.default \
	audio.r_submix.default \
	tinyplay

# libion needed by gralloc, ogl
PRODUCT_PACKAGES += libion iontest

# HAL
PRODUCT_PACKAGES += \
	gralloc.s5pxx18

# TODO
# kernel

# init.xxx.rc files
PRODUCT_COPY_FILES += \
	device/nexell/avn_ref/init.avn_ref.rc:root/init.avn_ref.rc \
	device/nexell/avn_ref/init.avn_ref.usb.rc:root/init.avn_ref.usb.rc \
	device/nexell/avn_ref/fstab.avn_ref:root/fstab.avn_ref \
	device/nexell/avn_ref/ueventd.avn_ref.rc:root/ueventd.avn_ref.rc

# media
PRODUCT_COPY_FILES += \
	frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:system/etc/media_codecs_google_audio.xml \
	frameworks/av/media/libstagefright/data/media_codecs_google_video.xml:system/etc/media_codecs_google_video.xml

# audio
PRODUCT_COPY_FILES += \
	frameworks/av/services/audiopolicy/config/a2dp_audio_policy_configuration.xml:system/etc/a2dp_audio_policy_configuration.xml \
	frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:system/etc/r_submix_audio_policy_configuration.xml \
	frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:system/etc/usb_audio_policy_configuration.xml \
	frameworks/av/services/audiopolicy/config/default_volume_tables.xml:system/etc/default_volume_tables.xml

# input
PRODUCT_COPY_FILES += \
	device/nexell/avn_ref/tsc2007.idc:system/usr/idc/tsc2007.idc \
	device/nexell/avn_ref/keypad_avn_ref.kl:system/usr/keylayout/keypad_avn_ref.kl \
	device/nexell/avn_ref/keypad_avn_ref.kcm:system/usr/keychars/keypad_avn_ref.kcm

# hardware features
PRODUCT_COPY_FILES += \
	frameworks/native/data/etc/tablet_core_hardware.xml:system/etc/permissions/tablet_core_hardware.xml \
	frameworks/native/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml \
	frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
	frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
	frameworks/native/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml \
	frameworks/native/data/etc/android.hardware.audio.low_latency.xml:system/etc/permissions/android.hardware.audio.low_latency.xml \
	frameworks/native/data/etc/android.hardware.opengles.aep.xml:system/etc/permissions/android.hardware.opengles.aep.xml

PRODUCT_TAGS += dalvik.gc.type-precise

# avn board 1024x600, 8inch
# dpi = math.sqrt(math.pow(1024,2) + math.pow(600,2))/8
# 148dpi ==> mdpi
# ldpi(low) ~120dpi
# mdpi(medium) ~160dpi
# hdpi(high) ~240dpi
# xhdpi(extra-high) ~320dpi
# xxhdpi(extra-extra-high) ~480dpi
# xxxhdpi(extra-extra-extra-high) ~640dpi
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := mdpi
PRODUCT_AAPT_PREBUILT_DPI := mdpi

PRODUCT_CHARACTERISTICS := tablet

# OpenGL ES API version: 2.0
PRODUCT_PROPERTY_OVERRIDES += \
	ro.opengles.version=131072

# density
PRODUCT_PROPERTY_OVERRIDES += \
	ro.sf.lcd_density=160

# TODO
# OpenGLRenderer(libhwui) properties
# see https://source.android.com/devices/tech/config/renderer.html

# TODO
# dalvik properties
# see https://source.android.com/devices/tech/dalvik/configure.html
$(call inherit-product, frameworks/native/build/tablet-dalvik-heap.mk)
