
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)

PRODUCT_NAME := avn_ref 
PRODUCT_DEVICE := avn_ref
PRODUCT_BRAND := avn_ref
PRODUCT_MODEL := avn_ref
PRODUCT_MANUFACTURER := Nexell

# automatically called
$(call inherit-product, device/nexell/avn_ref/device.mk)
