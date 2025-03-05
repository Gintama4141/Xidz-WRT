#!/bin/bash

# Source the include file containing common functions and variables
if [[ ! -f "./scripts/INCLUDE.sh" ]]; then
    error_msg "INCLUDE.sh not found in ./scripts/"
    exit 1
fi

. ./scripts/INCLUDE.sh

# Define repositories with proper quoting
declare -A REPOS
REPOS+=(
    ["KIDDIN9"]="https://dl.openwrt.ai/releases/24.10/packages/${ARCH_3}/kiddin9"
    ["IMMORTALWRT"]="https://downloads.immortalwrt.org/releases/packages-${VEROP}/${ARCH_3}"
    ["OPENWRT"]="https://downloads.openwrt.org/releases/packages-${VEROP}/${ARCH_3}"
    ["GSPOTX2F"]="https://github.com/gSpotx2f/packages-openwrt/raw/refs/heads/master/current"
    ["FANTASTIC"]="https://fantastic-packages.github.io/packages/releases/${VEROP}/packages/x86_64"
    ["DLLKIDS"]="https://op.dllkids.xyz/packages/${ARCH_3}"
)

# Define package categories with improved structure
declare -a packages_custom
packages_custom+=(
    "luci-proto-modemmanager_|${REPOS[OPENWRT]}/luci"
    "libqmi_|${REPOS[OPENWRT]}/packages"
    "libmbim_|${REPOS[OPENWRT]}/packages"
    "modemmanager_|${REPOS[OPENWRT]}/packages"
    "sms-tool_|${REPOS[OPENWRT]}/packages"
    "tailscale_|${REPOS[OPENWRT]}/packages"
    "luci-app-ttyd_|${REPOS[OPENWRT]}/luci"

    "luci-app-diskman_|${REPOS[KIDDIN9]}"
    "modeminfo-serial-fm350_|${REPOS[KIDDIN9]}"
    "modeminfo-serial-tw_|${REPOS[KIDDIN9]}"
    "modeminfo-serial-dell_|${REPOS[KIDDIN9]}"
    "modeminfo-serial-sierra_|${REPOS[KIDDIN9]}"
    "modeminfo-serial-xmm_|${REPOS[KIDDIN9]}"
    "modeminfo-serial-fibocom_|${REPOS[KIDDIN9]}"
    "modeminfo_|${REPOS[KIDDIN9]}"
    "luci-app-modeminfo_|${REPOS[KIDDIN9]}"
    "atinout_|${REPOS[KIDDIN9]}"
    "luci-app-poweroff_|${REPOS[KIDDIN9]}"
    "xmm-modem_|${REPOS[KIDDIN9]}"
    "luci-app-lite-watchdog_|${REPOS[KIDDIN9]}"
    "sing-box_|${REPOS[KIDDIN9]}"
    "mihomo_|${REPOS[KIDDIN9]}"

    "luci-app-zerotier_|${REPOS[IMMORTALWRT]}/luci"
    "luci-app-ramfree_|${REPOS[IMMORTALWRT]}/luci"
    "luci-app-oled_|${REPOS[KIDDIN9]}"
    "luci-app-tinyfm_|${REPOS[KIDDIN9]}"
    "modemband_|${REPOS[IMMORTALWRT]}/packages"
    "luci-app-modemband_|${REPOS[IMMORTALWRT]}/luci"
    "luci-app-sms-tool-js_|${REPOS[IMMORTALWRT]}/luci"
    "luci-app-mmconfig_|${REPOS[DLLKIDS]}"
    "dns2tcp_|${REPOS[IMMORTALWRT]}/packages"
    "luci-theme-argon_|${REPOS[IMMORTALWRT]}/luci"
    "luci-app-openclash_|${REPOS[IMMORTALWRT]}/luci"
    "luci-app-passwall_|${REPOS[IMMORTALWRT]}/luci"
    
    "speedtestcli_|${REPOS[KIDDIN9]}"
    "luci-app-eqosplus_|${REPOS[KIDDIN9]}"
    "luci-app-internet-detector_|${REPOS[GSPOTX2F]}"
    "internet-detector_|${REPOS[GSPOTX2F]}"
    "internet-detector-mod-modem-restart_|${REPOS[GSPOTX2F]}"
    "luci-app-temp-status_|${REPOS[GSPOTX2F]}"
    
    "luci-app-droidnet|https://api.github.com/repos/animegasan/luci-app-droidmodem/releases/latest"
    "luci-theme-alpha|https://api.github.com/repos/derisamedia/luci-theme-alpha/releases/latest"
    "luci-app-neko_|https://api.github.com/repos/nosignals/openwrt-neko/releases/latest"
)

if [ "${TYPE}" == "OPHUB" ]; then
    log "INFO" "Adding Amlogic-specific packages..."
    packages_custom+=(
        "luci-app-amlogic_|https://api.github.com/repos/ophub/luci-app-amlogic/releases/latest"
    )
fi

# Enhanced package verification function
verify_packages() {
    local pkg_dir="packages"
    local -a failed_packages=()
    local -a package_list=("${!1}")
    
    if [[ ! -d "$pkg_dir" ]]; then
        error_msg "Package directory not found: $pkg_dir"
        return 1
    fi
    
    local total_found=$(find "$pkg_dir" \( -name "*.ipk" -o -name "*.apk" \) | wc -l)
    log "INFO" "Found $total_found package files"
    
    for package in "${package_list[@]}"; do
        local pkg_name="${package%%|*}"
        if ! find "$pkg_dir" \( -name "${pkg_name}*.ipk" -o -name "${pkg_name}*.apk" \) -print -quit | grep -q .; then
            failed_packages+=("$pkg_name")
        fi
    done
    
    local failed=${#failed_packages[@]}
    
    if ((failed > 0)); then
        log "WARNING" "$failed packages failed to download:"
        for pkg in "${failed_packages[@]}"; do
            log "WARNING" "- $pkg"
        done
        return 1
    fi
    
    log "SUCCESS" "All packages downloaded successfully"
    return 0
}

# Main execution
main() {
    local rc=0
    
    # Download Custom packages
    log "INFO" "Downloading Custom packages..."
    download_packages packages_custom || rc=1
    
    # Verify all downloads
    log "INFO" "Verifying all packages..."
    verify_packages packages_custom || rc=1
    
    if [ $rc -eq 0 ]; then
        log "SUCCESS" "Package download and verification completed successfully"
    else
        error_msg "Package download or verification failed"
    fi
    
    return $rc
}

# Run main function if script is not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi