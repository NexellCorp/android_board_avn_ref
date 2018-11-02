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

LOCAL_PATH := device/nexell/avn_ref

# define targets
TARGET_BOARD_PLATFORM := s5pxx18
TARGET_BOOTLOADER_BOARD_NAME := avn_ref

TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a9

# do not stop building despite of build warning
BUILD_BROKEN_DUP_RULES := true

# below config must be false when SoC is s5p4418
TARGET_USES_64_BIT_BINDER := true

# images
TARGET_NO_BOOTLOADER := false 
TARGET_NO_KERNEL := false
TARGET_NO_RADIOIMAGE := true
TARGET_NO_RECOVERY := true

BOARD_BUILD_SYSTEM_ROOT_IMAGE := true

# boot image layout
BOARD_KERNEL_PAGESIZE := 2048
TARGET_BOOTLOADER_IS_2ND := true

# enable treble
PRODUCT_FULL_TREBLE_OVERRIDE := true
BOARD_VNDK_VERSION := current

# use split vendor partition
TARGET_COPY_OUT_VENDOR := vendor

# filesystem
TARGET_USERIMAGES_USE_EXT4 := true
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 1073741824
BOARD_SYSTEMIMAGE_JOURNAL_SIZE := 0
BOARD_SYSTEMIMAGE_EXTFS_INODE_COUNT := 4096
BOARD_VENDORIMAGE_PARTITION_SIZE := 268435456
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_PARTITION_SIZE := 6101663744
BOARD_FLASH_BLOCK_SIZE := 131072

# graphics
BOARD_EGL_CFG := $(LOCAL_PATH)/egl.cfg
USE_OPENGL_RENDERER := true
TARGET_USES_ION := true
NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3
# see surfaceflinger
MAX_VIRTUAL_DISPLAY_DIMENSION := 2048

#sepolicy
BOARD_SEPOLICY_DIRS := $(LOCAL_PATH)/sepolicy

# touch
BOARD_USES_TSLIB := true

# vendor interface manifest
DEVICE_MANIFEST_FILE := $(LOCAL_PATH)/manifest.xml

# HIDL configstore
VSYNC_EVENT_PHASE_OFFSET_NS := 0
SF_VSYNC_EVENT_PHASE_OFFSET_NS := 0
TARGET_USE_CONTEXT_PRIORITY := false
TARGET_HAS_WIDE_COLOR_DISPLAY := false
TARGET_HAS_HDR_DISPLAY := false
PRESENT_TIME_OFFSET_FROM_VSYNC_NS := 0
TARGET_FORCE_HWC_FOR_VIRTUAL_DISPLAYS := false
MAX_VIRTUAL_DISPLAY_DIMENSION := 2048
TARGET_RUNNING_WITHOUT_SYNC_FRAMEWORK := true
NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3
SF_PRIMARY_DISPLAY_ORIENTATION := 0

# audio
BOARD_USES_GENERIC_AUDIO := false
BOARD_USES_ALSA_AUDIO := false

# camera
BOARD_CAMERA_BACK_DEVICE := "6"
BOARD_CAMERA_BACK_ORIENTATION := "0"
BOARD_CAMERA_BACK_INTERLACED := "1"
BOARD_CAMERA_NUM := 1
BOARD_CAMERA_USE_ZOOM := false
