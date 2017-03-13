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

TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic

ENABLE_CPUSETS := true

# TODO: afterwards fixup below setting
TARGET_NO_BOOTLOADER := true
TARGET_NO_KERNEL := true
TARGET_NO_RADIOIMAGE := true

TARGET_BOARD_PLATFORM := s5p6818
TARGET_BOOTLOADER_BOARD_NAME := avn_ref
TARGET_BOARD_INFO_FILE := device/nexell/avn_ref/board-info.txt

BOARD_USES_GENERIC_AUDIO := false
BOARD_USES_ALSA_AUDIO := false

# TODO: wifi

BOARD_EGL_CFG := device/nexell/avn_ref/egl.cfg
USE_OPENGL_RENDERER := true
TARGET_USES_ION := true
NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3
# see surfaceflinger
TARGET_FORCE_HWC_FOR_VIRTUAL_DISPLAYS := true
MAX_VIRTUAL_DISPLAY_DIMENSION := 2048

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
BOARD_BOOTIMAGE_PARTITION_SIZE := 33554432
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2147483648
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_PARTITION_SIZE := 100663296
BOARD_USERDATAIMAGE_PARTITION_SIZE := 5532286976
BOARD_FLASH_BLOCK_SIZE           := 131072

TARGET_USES_64_BIT_BINDER := true
TARGET_USES_AOSP := true

USE_CLANG_PLATFORM_BUILD := true
