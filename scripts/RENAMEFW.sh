#!/bin/bash

. ./scripts/INCLUDE.sh

rename_firmware() {
    echo -e "${STEPS} Renaming firmware files..."

    # Validasi direktori firmware
    local firmware_dir="$GITHUB_WORKSPACE/$WORKING_DIR/compiled_images"
    if [[ ! -d "$firmware_dir" ]]; then
        error_msg "Invalid firmware directory: ${firmware_dir}"
    fi

    # Pindah ke direktori firmware
    cd "${firmware_dir}" || {
       error_msg "Failed to change directory to ${firmware_dir}"
    }

    # Pola pencarian dan penggantian
    local search_replace_patterns=(
        # Format: "search|replace"

        # bcm27xx
        "-bcm27xx-bcm2710-rpi-3-ext4-factory|Broadcom_RaspberryPi_3B-Ext4_Factory"
        "-bcm27xx-bcm2710-rpi-3-ext4-sysupgrade|Broadcom_RaspberryPi_3B-Ext4_Sysupgrade"
        "-bcm27xx-bcm2710-rpi-3-squashfs-factory|Broadcom_RaspberryPi_3B-Squashfs_Factory"
        "-bcm27xx-bcm2710-rpi-3-squashfs-sysupgrade|Broadcom_RaspberryPi_3B-Squashfs_Sysupgrade"

        "-bcm27xx-bcm2711-rpi-4-ext4-factory|Broadcom_RaspberryPi_4B-Ext4_Factory"
        "-bcm27xx-bcm2711-rpi-4-ext4-sysupgrade|Broadcom_RaspberryPi_4B-Ext4_Sysupgrade"
        "-bcm27xx-bcm2711-rpi-4-squashfs-factory|Broadcom_RaspberryPi_4B-Squashfs_Factory"
        "-bcm27xx-bcm2711-rpi-4-squashfs-sysupgrade|Broadcom_RaspberryPi_4B-Squashfs_Sysupgrade"
        
        "-bcm27xx-bcm2712-rpi-5-ext4-factory|Broadcom_RaspberryPi_5B-Ext4_Factory"
        "-bcm27xx-bcm2712-rpi-5-ext4-sysupgrade|Broadcom_RaspberryPi_5B-Ext4_Sysupgrade"
        "-bcm27xx-bcm2712-rpi-5-squashfs-factory|Broadcom_RaspberryPi_5B-Squashfs_Factory"
        "-bcm27xx-bcm2712-rpi-5-squashfs-sysupgrade|Broadcom_RaspberryPi_5B-Squashfs_Sysupgrade"
        
        # Allwinner
        "-h5-orangepi-pc2-|Allwinner_OrangePi_PC2"
        "-h5-orangepi-prime-|Allwinner_OrangePi_Prime"
        "-h5-orangepi-zeroplus-|Allwinner_OrangePi_ZeroPlus"
        "-h5-orangepi-zeroplus2-|Allwinner_OrangePi_ZeroPlus2"
        "-h6-orangepi-1plus-|Allwinner_OrangePi_1Plus"
        "-h6-orangepi-3-|Allwinner_OrangePi_3"
        "-h6-orangepi-3lts-|Allwinner_OrangePi_3LTS"
        "-h6-orangepi-lite2-|Allwinner_OrangePi_Lite2"
        "-h616-orangepi-zero2-|Allwinner_OrangePi_Zero2"
        "-h618-orangepi-zero2w-|Allwinner_OrangePi_Zero2W"
        "-h618-orangepi-zero3-|Allwinner_OrangePi_Zero3"
        
        # Rockchip
        "-rk3566-orangepi-3b-|Rockchip_OrangePi_3B"
        "-rk3588s-orangepi-5-|Rockchip_OrangePi_5"
        
        # Sunxi-Cortex-A53
        "-xunlong_orangepi-zero-plus-|Orangepi-Zero-Plus-sunxi-Cortexa53"
        "-xunlong_orangepi-zero2-|Orangepi-Zero2-Sunxi-Cortexa53"
        "-xunlong_orangepi-zero3-|Orangepi-Zero3-Sunxi-Cortexa53"
        
        # Amlogic ULO
        "-s905x2-v5-|Amlogic_s905x2-B860Hv5"
        "-s905x2-fj-|Amlogic_s905x2-HG680-FJ"
        "-s905x3-|Amlogic_s905x3"
        "-s905x4-|Amlogic_s905x4"
        
        # Amlogic Ophub
        "_s905x_|Amlogic_HG680P"
        "_s905x-b860h_|Amlogic_B860H"
        "_s912-nexbox-a1_|Amlogic_s912_NEXBOX_A1"
        "_s905l2_|Amlogic_s905l2_MGV_M301A"
        "_s905x2-x96max-2g_|Amlogic_s905x2-x96Max2Gb"
        "_s905x2_|Amlogic_s905x2_x96Max-4Gb"
        "_s905x3-x96air_|Amlogic_s905x3-X96Air100M"
        "_s905x3-x96air-gb_|Amlogic_s905x3-x96Air1Gbps"
        "_s905x3-hk1_|Amlogic_s905x3-HK1BOX"
        "_s905x3_|Amlogic_s905x3_X96MAX+_100Mb"
        "_s905x3-x96max_|Amlogic_s905x3_X96MAX+_1Gb"

        # x86_64
        "x86-64-generic-ext4-combined-efi|X86_64_Generic_Ext4_Combined_EFI"
        "x86-64-generic-ext4-combined|X86_64_Generic_Ext4_Combined"
        "x86-64-generic-ext4-rootfs|X86_64_Generic_Ext4_Rootfs"
        "x86-64-generic-squashfs-combined-efi|X86_64_Generic_Squashfs_Combined_EFI"
        "x86-64-generic-squashfs-combined|X86_64_Generic_Squashfs_Combined"
        "x86-64-generic-squashfs-rootfs|X86_64_Generic_Squashfs_Rootfs"
        "x86-64-generic-rootfs|X86_64_Generic_Rootfs"
    )

   for pattern in "${search_replace_patterns[@]}"; do
        local search="${pattern%%|*}"
        local replace="${pattern##*|}"

        for file in *"${search}"*.img.gz; do
            if [[ -f "$file" ]]; then
                local kernel=""
                if [[ "$file" =~ k[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9-]+)? ]]; then
                    kernel="${BASH_REMATCH[0]}"
                fi
                local new_name
                if [[ -n "$kernel" ]]; then
                    new_name="One-WRT-${BRANCH}-${replace}-${kernel}-${TUNNEL}.img.gz"
                else
                    new_name="One-WRT-${BRANCH}-${replace}-${TUNNEL}.img.gz"
                fi
                echo -e "${INFO} Renaming: $file → $new_name"
                mv "$file" "$new_name" || {
                    echo -e "${WARN} Failed to rename $file"
                    continue
                }
            fi
        done
        for file in *"${search}"*.tar.gz; do
            if [[ -f "$file" ]]; then
                local new_name
                new_name="One-WRT-${OP_BASE}-${BRANCH}-${replace}-${TUNNEL}.tar.gz"
                echo -e "${INFO} Renaming: $file → $new_name"
                mv "$file" "$new_name" || {
                    echo -e "${WARN} Failed to rename $file"
                    continue
                }
            fi
        done
    done

    sync && sleep 3
    echo -e "${INFO} Rename operation completed."
}

rename_firmware