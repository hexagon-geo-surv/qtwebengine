include(common.pri)
load(functions)

# Reuse the cached sdk version value from mac/sdk.prf if available
# otherwise query for it.
QMAKE_MAC_SDK_VERSION = $$eval(QMAKE_MAC_SDK.$${QMAKE_MAC_SDK}.SDKVersion)
isEmpty(QMAKE_MAC_SDK_VERSION) {
     QMAKE_MAC_SDK_VERSION = $$system("/usr/bin/xcodebuild -sdk $${QMAKE_MAC_SDK} -version SDKVersion 2>/dev/null")
     isEmpty(QMAKE_MAC_SDK_VERSION): error("Could not resolve SDK version for \'$${QMAKE_MAC_SDK}\'")
}

QMAKE_CLANG_DIR = "/usr"
QMAKE_CLANG_PATH = $$eval(QMAKE_MAC_SDK.macx-clang.$${QMAKE_MAC_SDK}.QMAKE_CXX)
!isEmpty(QMAKE_CLANG_PATH) {
    clang_dir = $$clean_path("$$dirname(QMAKE_CLANG_PATH)/../")
    exists($$clang_dir): QMAKE_CLANG_DIR = $$clang_dir
}

QMAKE_CLANG_PATH = "$${QMAKE_CLANG_DIR}/bin/clang++"
message("Using clang++ from $${QMAKE_CLANG_PATH}")
system("$${QMAKE_CLANG_PATH} --version")


use?(gn) {
    gn_args += \
        is_clang=true \
        use_sysroot=false \
        use_kerberos=false \
        clang_base_path=\"$${QMAKE_CLANG_DIR}\" \
        clang_use_chrome_plugins=false \
        mac_deployment_target=\"$${QMAKE_MACOSX_DEPLOYMENT_TARGET}\" \
        mac_sdk_min=\"$${QMAKE_MAC_SDK_VERSION}\"

    use?(spellchecker) {
        use?(native_spellchecker): gn_args += use_browser_spellchecker=true
        else: gn_args += use_browser_spellchecker=false
    } else {
        macos: gn_args += use_browser_spellchecker=false
    }

} else {
    GYP_CONFIG += \
        qt_os=\"mac\" \
        mac_sdk_min=\"$${QMAKE_MAC_SDK_VERSION}\" \
        mac_deployment_target=\"$${QMAKE_MACOSX_DEPLOYMENT_TARGET}\" \
        make_clang_dir=\"$${QMAKE_CLANG_DIR}\" \
        clang_use_chrome_plugins=0

    # Force touch API is used in 49-based Chromium, which is included starting with 10.10.3 SDK, so we
    # disable the API usage if the SDK version is lower.
    !isMinOSXSDKVersion(10, 10, 3): GYP_CONFIG += disable_force_touch=1

    # Pass a supported -fstack-protect flag depending on Xcode version.
    lessThan(QMAKE_XCODE_VERSION, 6.3) {
      GYP_CONFIG += use_xcode_stack_protector_strong=0
    }

    QMAKE_MAC_SDK_PATH = "$$eval(QMAKE_MAC_SDK.$${QMAKE_MAC_SDK}.path)"
    exists($$QMAKE_MAC_SDK_PATH): GYP_CONFIG += mac_sdk_path=\"$${QMAKE_MAC_SDK_PATH}\"
}
