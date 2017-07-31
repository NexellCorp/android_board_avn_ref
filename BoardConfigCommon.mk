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

TARGET_BOOTLOADER_BOARD_NAME := avn_ref
TARGET_BOARD_INFO_FILE := device/nexell/avn_ref/board-info.txt

ENABLE_CPUSETS := true

TARGET_NO_BOOTLOADER := false
TARGET_NO_KERNEL := false
TARGET_NO_RADIOIMAGE := true
TARGET_NO_RECOVERY := false

# recovery
TARGET_RELEASETOOLS_EXTENSIONS := device/nexell/avn_ref
TARGET_RECOVERY_UPDATER_LIBS := librecovery_updater_nexell
TARGET_RECOVERY_FSTAB := device/nexell/avn_ref/recovery.fstab

BOARD_USES_GENERIC_AUDIO := false
BOARD_USES_ALSA_AUDIO := false

BOARD_EGL_CFG := device/nexell/avn_ref/egl.cfg
USE_OPENGL_RENDERER := true
TARGET_USES_ION := true
NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3
# see surfaceflinger
MAX_VIRTUAL_DISPLAY_DIMENSION := 2048

# hwcomposer
BOARD_USES_NX_HWCOMPOSER := true

# Enable dex-preoptimization to speed up first boot sequence
ifeq ($(HOST_OS),linux)
  ifneq ($(TARGET_BUILD_VARIANT),eng)
    ifeq ($(WITH_DEXPREOPT),)
      WITH_DEXPREOPT := true
      WITH_DEXPREOPT_PIC := true
    endif
  endif
endif

# touch
BOARD_USES_TSLIB := true

# bluetooth
BOARD_HAVE_BLUETOOTH := false

BOARD_CHARGER_ENABLE_SUSPEND := false

# sepolicy
BOARD_SEPOLICY_DIRS += \
	device/nexell/avn_ref/sepolicy

# filesystems
TARGET_USERIMAGES_USE_EXT4 := true
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2147483648
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_PARTITION_SIZE := 536870912
BOARD_USERDATAIMAGE_PARTITION_SIZE := 4920246272
BOARD_FLASH_BLOCK_SIZE := 131072

# boot image layout
BOARD_KERNEL_PAGESIZE := 2048
TARGET_BOOTLOADER_IS_2ND := true

TARGET_USES_AOSP := true

USE_CLANG_PLATFORM_BUILD := true

# FFMPEG
EN_FFMPEG_EXTRACTOR := true
EN_FFMPEG_AUDIO_DEC := true

# wifi
BOARD_WIFI_VENDOR := realtek
WPA_SUPPLICANT_VERSION      := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER	:= NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_rtl
BOARD_HOSTAPD_DRIVER		:= NL80211
BOARD_HOSTAPD_PRIVATE_LIB	:= lib_driver_cmd_rtl

BOARD_WLAN_DEVICE	:= rtl8188eu

WIFI_DRIVER_MODULE_NAME		:= "wlan"
WIFI_DRIVER_MODULE_PATH		:= "/system/vendor/realtek/wlan.ko"
WIFI_DRIVER_MODULE_ARG		:= "ifname=wlan0 if2name=p2p0"

WIFI_FIRMWARE_LOADER		:= "rtw"
WIFI_DRIVER_FW_PATH_STA		:= "STA"
WIFI_DRIVER_FW_PATH_AP		:= "AP"
WIFI_DRIVER_FW_PATH_P2P		:= "P2P"
WIFI_DRIVER_FW_PATH_PARAM	:= "/dev/null"

# certificate
PRODUCT_DEFAULT_DEV_CERTIFICATE := device/nexell/avn_ref/signing_keys/release
