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

# Recovery
PRODUCT_PACKAGES += \
	librecovery_updater_nexell

PRODUCT_COPY_FILES += \
	device/nexell/avn_ref/init.avn_ref.usb.rc:root/init.avn_ref.usb.rc \
	device/nexell/avn_ref/ueventd.avn_ref.rc:root/ueventd.avn_ref.rc

PRODUCT_COPY_FILES += \
	frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:system/etc/media_codecs_google_audio.xml \
	frameworks/av/media/libstagefright/data/media_codecs_google_video.xml:system/etc/media_codecs_google_video.xml

# audio
USE_XML_AUDIO_POLICY_CONF := 1
PRODUCT_COPY_FILES += \
	device/nexell/avn_ref/mixer_paths.xml:system/etc/mixer_paths.xml \
	device/nexell/avn_ref/audio_policy_configuration.xml:system/etc/audio_policy_configuration.xml \
	device/nexell/avn_ref/audio_policy_volumes.xml:system/etc/audio_policy_volumes.xml \
	device/nexell/avn_ref/a2dp_audio_policy_configuration.xml:system/etc/a2dp_audio_policy_configuration.xml \
	device/nexell/avn_ref/usb_audio_policy_configuration.xml:system/etc/usb_audio_policy_configuration.xml \
	device/nexell/avn_ref/r_submix_audio_policy_configuration.xml:system/etc/r_submix_audio_policy_configuration.xml \
	device/nexell/avn_ref/default_volume_tables.xml:system/etc/default_volume_tables.xml

PRODUCT_COPY_FILES += \
	device/nexell/avn_ref/audio/tiny_hw.avn_ref.xml:system/etc/tiny_hw.avn_ref.xml \
	device/nexell/avn_ref/audio/audio_policy.conf:system/etc/audio_policy.conf

PRODUCT_COPY_FILES += \
	frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:system/etc/media_codecs_google_audio.xml \
	device/nexell/avn_ref/media_codecs.xml:system/etc/media_codecs.xml \
	device/nexell/avn_ref/media_profiles.xml:system/etc/media_profiles.xml \
	frameworks/native/data/etc/android.hardware.camera.xml:system/etc/permissions/android.hardware.camera.xml


# ffmpeg libraries
EN_FFMPEG_EXTRACTOR := false
EN_FFMPEG_AUDIO_DEC := false

ifeq ($(EN_FFMPEG_EXTRACTOR),true)

PRODUCT_COPY_FILES += \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavcodec.so:system/lib/libavcodec.so    \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavcodec.so.55:system/lib/libavcodec.so.55    \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavcodec.so.55.39.101:system/lib/libavcodec.so.55.39.101    \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavdevice.so:system/lib/libavdevice.so  \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavdevice.so.55:system/lib/libavdevice.so.55  \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavdevice.so.55.5.100:system/lib/libavdevice.so.55.5.100  \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavfilter.so:system/lib/libavfilter.so  \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavfilter.so.3:system/lib/libavfilter.so.3  \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavfilter.so.3.90.100:system/lib/libavfilter.so.3.90.100  \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavformat.so:system/lib/libavformat.so  \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavformat.so.55:system/lib/libavformat.so.55  \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavformat.so.55.19.104:system/lib/libavformat.so.55.19.104  \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavresample.so:system/lib/libavresample.so      \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavresample.so.1:system/lib/libavresample.so.1      \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavresample.so.1.1.0:system/lib/libavresample.so.1.1.0      \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavutil.so:system/lib/libavutil.so      \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavutil.so.52:system/lib/libavutil.so.52      \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libavutil.so.52.48.101:system/lib/libavutil.so.52.48.101      \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libswresample.so:system/lib/libswresample.so \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libswresample.so.0:system/lib/libswresample.so.0 \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libswresample.so.0.17.104:system/lib/libswresample.so.0.17.104 \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libswscale.so:system/lib/libswscale.so \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libswscale.so.2:system/lib/libswscale.so.2 \
	hardware/nexell/s5pxx18/omx/codec/ffmpeg/32bit/libs/libswscale.so.2.5.101:system/lib/libswscale.so.2.5.101

endif	#EN_FFMPEG_EXTRACTOR

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
	camera.avn_ref \
    lights.avn_ref

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

# omx
PRODUCT_PACKAGES += \
	libstagefrighthw \
	libnx_video_api \
	libNX_OMX_VIDEO_DECODER \
	libNX_OMX_VIDEO_ENCODER \
	libNX_OMX_Base \
	libNX_OMX_Core \
	libNX_OMX_Common

# stagefright FFMPEG compnents
ifeq ($(EN_FFMPEG_AUDIO_DEC),true)
PRODUCT_PACKAGES += libNX_OMX_AUDIO_DECODER_FFMPEG
endif

ifeq ($(EN_FFMPEG_EXTRACTOR),true)
PRODUCT_PACKAGES += libNX_FFMpegExtractor
endif

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

# set default none for usb
PRODUCT_PROPERTY_OVERRIDES += \
	persist.sys.usb.config=none

#skip boot jars check
SKIP_BOOT_JARS_CHECK := true

$(call inherit-product, frameworks/base/data/fonts/fonts.mk)

# carlife with android phone
PRODUCT_PACKAGES += \
	libbdcl \
	libdiagnose_usb_bdcl \
	bdcl

# carlife with iphone
ifeq ($(TARGET_ARCH),arm)
PRODUCT_PACKAGES += \
	libusb1.0 \
	libcnary \
	libplist \
	libplist++ \
	plist_cmp \
	plist_test \
	plist_util \
	libusbmuxdcommon \
	libusbmuxd \
	iproxy \
	libcrypto_openssl \
	libimobilecommon \
	libmobiledevice \
	ideviceinfo \
	idevicename \
	idevicepair \
	idevicesyslog \
	idevice_id \
	idevicebackup \
	idevicebackup2 \
	ideviceimagemounter \
	idevicescreenshot \
	ideviceenterrecovery \
	idevicedate \
	ideviceprovision \
	idevicedebugserverproxy \
	idevicediagnostics \
	idevicedebug \
	idevicenotificationproxy \
	idevicecrashreport \
	usbmuxd \
	libzip \
	ideviceinstaller
endif

PRODUCT_COPY_FILES += \
	device/nexell/avn_ref/iproxy.sh:system/bin/iproxy.sh

PRODUCT_PROPERTY_OVERRIDES += \
	config.disable_bluetooth=true
