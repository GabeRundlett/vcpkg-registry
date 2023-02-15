vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL https://github.com/GabeRundlett/gvox
    REF 3303f27de31b1f303193a6e11043df904a05aace
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
    file-io WITH_FILE_IO
)

list(APPEND GVOX_DEFINES "-DGVOX_ENABLE_THREADSAFETY=true")
if(WITH_FILE_IO)
    list(APPEND GVOX_DEFINES "-DGVOX_ENABLE_FILE_IO=true")
endif()

vcpkg_configure_cmake(
    SOURCE_PATH "${SOURCE_PATH}"
    PREFER_NINJA
    OPTIONS ${GVOX_DEFINES}
)

vcpkg_install_cmake()
vcpkg_fixup_cmake_targets()
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(INSTALL "${SOURCE_PATH}/LICENSE"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
