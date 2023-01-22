vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL https://github.com/Ipotrick/Daxa
    REF 2df08cdb1cd3d3db1ea676fceea86b58b57c6a50
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
    utils-fsr2 WITH_UTILS_FSR2
    utils-imgui WITH_UTILS_IMGUI
    utils-mem WITH_UTILS_MEM
    utils-pipeline-manager-glslang WITH_UTILS_PIPELINE_MANAGER_GLSLANG
    utils-pipeline-manager-dxc WITH_UTILS_PIPELINE_MANAGER_DXC
    utils-task-list WITH_UTILS_TASK_LIST
)
set(DAXA_DEFINES)

if(WITH_UTILS_FSR2)
    list(APPEND DAXA_DEFINES "-DDAXA_ENABLE_UTILS_FSR2=true")
endif()
if(WITH_UTILS_IMGUI)
    list(APPEND DAXA_DEFINES "-DDAXA_ENABLE_UTILS_IMGUI=true")
endif()
if(WITH_UTILS_MEM)
    list(APPEND DAXA_DEFINES "-DDAXA_ENABLE_UTILS_MEM=true")
endif()
if(WITH_UTILS_PIPELINE_MANAGER_GLSLANG)
    list(APPEND DAXA_DEFINES "-DDAXA_ENABLE_UTILS_PIPELINE_MANAGER_GLSLANG=true")
endif()
if(WITH_UTILS_PIPELINE_MANAGER_DXC)
    list(APPEND DAXA_DEFINES "-DDAXA_ENABLE_UTILS_PIPELINE_MANAGER_DXC=true")
endif()
if(WITH_UTILS_TASK_LIST)
    list(APPEND DAXA_DEFINES "-DDAXA_ENABLE_UTILS_TASK_LIST=true")
endif()

vcpkg_configure_cmake(
    SOURCE_PATH "${SOURCE_PATH}"
    PREFER_NINJA
    OPTIONS ${DAXA_DEFINES}
)

vcpkg_install_cmake()
vcpkg_fixup_cmake_targets()
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(INSTALL "${SOURCE_PATH}/LICENSE"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
