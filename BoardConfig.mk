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

ifeq ($(TARGET_SOC),s5p6818)
-include device/nexell/avn_ref/TargetArm64Config.mk
endif

ifeq ($(TARGET_SOC),s5p4418)
-include device/nexell/avn_ref/TargetArmConfig.mk
endif

ifeq ($(TARGET_SOC),nxp4330)
-include device/nexell/avn_ref/TargetArmConfig.mk
endif

# TODO: check below feature
# ENABLE_CPUSETS := true

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
# see surfaceflinger
TARGET_FORCE_HWC_FOR_VIRTUAL_DISPLAYS := true
MAX_VIRTUAL_DISPLAY_DIMENSION := 2048

# Enable dex-preoptimization to speed up first boot sequence
ifeq ($(HOST_OS),linux)
  ifneq ($(TARGET_BUILD_VARIANT),eng)
    ifeq ($(WITH_DEXPREOPT),)
      WITH_DEXPREOPT := true
    endif
  endif
endif

BOARD_CHARGER_ENABLE_SUSPEND := false

TARGET_USERIMAGES_USE_EXT4       := true
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 790626304
BOARD_CACHEIMAGE_PARTITION_SIZE  := 448790528
BOARD_USERDATAIMAGE_PARTITION_SIZE := 7215251456
# BOARD_FLASH_BLOCK_SIZE           := 4096
BOARD_FLASH_BLOCK_SIZE           := 131072
