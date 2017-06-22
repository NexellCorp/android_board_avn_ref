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

PRODUCT_SHIPPING_API_LEVEL := 25

PRODUCT_PACKAGES := \
    AccountAndSyncSettings \
    DeskClock \
    AlarmProvider \
    Calculator \
    Calendar \
    Camera \
    CertInstaller \
    Email \
    Gallery2 \
    LatinIME \
    Provision \
    QuickSearchBox \
    Settings \
    Sync \
    SystemUI \
    CalendarProvider \
    SyncProvider \
	Stk

# Live Wallpapers
PRODUCT_PACKAGES += \
	LiveWallpapers \
	LiveWallpapersPicker \
	VisualizationWallpapers \
	librs_jni

# Filesystem management tools
PRODUCT_PACKAGES += \
    make_ext4fs \
    setup_fs

PRODUCT_COPY_FILES += \
	device/nexell/avn_ref/init.avn_ref.usb.rc:root/init.avn_ref.usb.rc \
	device/nexell/avn_ref/fstab.avn_ref:root/fstab.avn_ref \
	device/nexell/avn_ref/ueventd.avn_ref.rc:root/ueventd.avn_ref.rc

PRODUCT_COPY_FILES += \
	frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:system/etc/media_codecs_google_audio.xml \
	frameworks/av/media/libstagefright/data/media_codecs_google_video.xml:system/etc/media_codecs_google_video.xml

# audio
PRODUCT_COPY_FILES += \
	frameworks/av/services/audiopolicy/config/a2dp_audio_policy_configuration.xml:system/etc/a2dp_audio_policy_configuration.xml \
	frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:system/etc/r_submix_audio_policy_configuration.xml \
	frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:system/etc/usb_audio_policy_configuration.xml \
	frameworks/av/services/audiopolicy/config/default_volume_tables.xml:system/etc/default_volume_tables.xml

PRODUCT_COPY_FILES += \
	device/nexell/avn_ref/audio/tiny_hw.avn_ref.xml:system/etc/tiny_hw.avn_ref.xml \
	device/nexell/avn_ref/audio/audio_policy.conf:system/etc/audio_policy.conf

PRODUCT_COPY_FILES += \
	frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:system/etc/media_codecs_google_audio.xml \
	device/nexell/avn_ref/media_codecs.xml:system/etc/media_codecs.xml

# input
PRODUCT_COPY_FILES += \
	device/nexell/avn_ref/TSC2007_Touchscreen.idc:system/usr/idc/TSC2007_Touchscreen.idc \
	device/nexell/avn_ref/gpio_keys.kl:system/usr/keylayout/gpio_keys.kl \
	device/nexell/avn_ref/gpio_keys.kcm:system/usr/keychars/gpio_keys.kcm

# hardware features
PRODUCT_COPY_FILES += \
	device/nexell/avn_ref/tablet_core_hardware.xml:system/etc/permissions/tablet_core_hardware.xml \
	frameworks/native/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml \
	frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
	frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
	frameworks/native/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml \
	frameworks/native/data/etc/android.hardware.audio.low_latency.xml:system/etc/permissions/android.hardware.audio.low_latency.xml \
	frameworks/native/data/etc/android.hardware.faketouch.xml:system/etc/permissions/android.hardware.faketouch.xml

# wallpaper
PRODUCT_COPY_FILES += \
	device/nexell/avn_ref/wallpaper:/data/system/users/0/wallpaper \
	device/nexell/avn_ref/wallpaper_orig:/data/system/users/0/wallpaper_orig \
	device/nexell/avn_ref/wallpaper_info.xml:/data/system/users/0/wallpaper_info.xml

PRODUCT_TAGS += dalvik.gc.type-precise

PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_CONFIG += mdpi xlarge large
PRODUCT_AAPT_PREF_CONFIG := mdpi
PRODUCT_AAPT_PREBUILT_DPI := hdpi mdpi ldpi
PRODUCT_CHARACTERISTICS := tablet

# OpenGL ES API version: 2.0
PRODUCT_PROPERTY_OVERRIDES += \
	ro.opengles.version=131072

# density
PRODUCT_PROPERTY_OVERRIDES += \
	ro.sf.lcd_density=160

PRODUCT_PACKAGES += \
	audio.a2dp.default \
	audio.usb.default \
	audio.r_submix.default \
	tinyplay

# libion needed by gralloc, ogl
PRODUCT_PACKAGES += libion iontest

PRODUCT_PACKAGES += libdrm

# HAL
PRODUCT_PACKAGES += \
	gralloc.avn_ref \
	libGLES_mali \
	hwcomposer.avn_ref \
	audio.primary.avn_ref \
	memtrack.avn_ref \
	camera.avn_ref

# tinyalsa
PRODUCT_PACKAGES += \
	libtinyalsa \
	tinyplay \
	tinycap \
	tinymix \
	tinypcminfo

PRODUCT_PACKAGES += fs_config_files

PRODUCT_PACKAGES += \
	libtslib \
	inputraw \
	pthres \
	dejitter \
	linear \
	tscalib

PRODUCT_COPY_FILES += \
	external/tslib/ts.conf:system/etc/ts.conf \
	device/nexell/avn_ref/pointercal:system/etc/pointercal

# wifi
PRODUCT_PACKAGES += \
    libwpa_client \
    hostapd \
    wpa_supplicant \
    wpa_supplicant.conf

PRODUCT_PACKAGES += \
	rtw_fwloader

PRODUCT_COPY_FILES += \
	hardware/realtek/wlan/driver/rtl8188eus/wlan.ko:system/vendor/realtek/wlan.ko

PRODUCT_PROPERTY_OVERRIDES += \
	wifi.interface=wlan0

# $(call inherit-product-if-exists, hardware/realtek/wlan/config/p2p_supplicant.mk)

DEVICE_PACKAGE_OVERLAYS := device/nexell/avn_ref/overlay

# increase dex2oat threads to improve booting time
PRODUCT_PROPERTY_OVERRIDES += \
	dalvik.vm.boot-dex2oat-threads=8 \
	dalvik.vm.dex2oat-threads=8 \
	dalvik.vm.image-dex2oat-threads=8

#Enabling video for live effects
-include frameworks/base/data/videos/VideoPackage1.mk

PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.heapstartsize=16m \
    dalvik.vm.heapgrowthlimit=256m \
    dalvik.vm.heapsize=512m \
    dalvik.vm.heaptargetutilization=0.75 \
    dalvik.vm.heapminfree=512k \
    dalvik.vm.heapmaxfree=8m

# HWUI common settings
PRODUCT_PROPERTY_OVERRIDES += \
    ro.hwui.gradient_cache_size=1 \
    ro.hwui.drop_shadow_cache_size=6 \
    ro.hwui.r_buffer_cache_size=8 \
    ro.hwui.texture_cache_flushrate=0.4 \
    ro.hwui.text_small_cache_width=1024 \
    ro.hwui.text_small_cache_height=1024 \
    ro.hwui.text_large_cache_width=2048 \
    ro.hwui.text_large_cache_height=1024

#skip boot jars check
SKIP_BOOT_JARS_CHECK := true

$(call inherit-product, frameworks/base/data/fonts/fonts.mk)
