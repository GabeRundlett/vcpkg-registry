vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL https://github.com/GPUOpen-Effects/FidelityFX-FSR2
    REF 2e6d42ad0a6822c934ffc6121c1e9541af870777
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
    directx12 WITH_DX12
    vulkan WITH_VULKAN
    volk WITH_VOLK
)
set(FSR2_DEFINES)

file(WRITE "${SOURCE_PATH}/src/ffx-fsr2-api/CMakeLists.txt" [==[
cmake_minimum_required(VERSION 3.15)
project(ffx_fsr2_api VERSION 2.0.1)
set(CMAKE_DEBUG_POSTFIX d)
option(FFX_FSR2_API_DX12 "Build FSR 2.0 DX12 backend" ON)
option(FFX_FSR2_API_VK "Build FSR 2.0 Vulkan backend" ON)
set(FSR2_AUTO_COMPILE_SHADERS ON CACHE BOOL "Compile shaders automatically as a prebuild step.")

if(CMAKE_GENERATOR STREQUAL "Ninja")
    set(USE_DEPFILE TRUE)
else()
    set(USE_DEPFILE FALSE)
endif()

if(CMAKE_GENERATOR STREQUAL "Visual Studio 16 2019")
    set(FSR2_VS_VERSION 2019)
endif()

if(CMAKE_GENERATOR MATCHES "Visual Studio")
    if(CMAKE_GENERATOR_PLATFORM STREQUAL "x64" OR CMAKE_EXE_LINKER_FLAGS STREQUAL "/machine:x64")
    else()
        message(FATAL_ERROR "Unsupported target platform - only supporting x64 and Win32 currently")
    endif()
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /Z7")
endif()

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG ${CMAKE_HOME_DIRECTORY}/bin/ffx_fsr2_api/)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE ${CMAKE_HOME_DIRECTORY}/bin/ffx_fsr2_api/)
add_compile_definitions(_UNICODE)
add_compile_definitions(UNICODE)

if(FSR2_VS_VERSION STREQUAL 2015)
    message(NOTICE "Forcing the SDK path for VS 2015")
    set(CMAKE_VS_WINDOWS_TARGET_PLATFORM_VERSION "10.0.18362.0")
endif()

set(FFX_SC_EXECUTABLE ${CMAKE_CURRENT_SOURCE_DIR}/../../tools/sc/FidelityFX_SC.exe)
set(FFX_SC_BASE_ARGS -reflection -deps=gcc -DFFX_GPU=1 -DOPT_PRECOMPUTE_REACTIVE_MAX=1)

set(FFX_SC_PERMUTATION_ARGS
    -DFFX_FSR2_OPTION_USE_LANCZOS_LUT={0,1}
    -DFFX_FSR2_OPTION_HDR_COLOR_INPUT={0,1}
    -DFFX_FSR2_OPTION_LOW_RESOLUTION_MOTION_VECTORS={0,1}
    -DFFX_FSR2_OPTION_JITTERED_MOTION_VECTORS={0,1}
    -DFFX_FSR2_OPTION_INVERTED_DEPTH={0,1}
    -DFFX_FSR2_OPTION_APPLY_SHARPENING={0,1})

file(GLOB SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/*.h")

if(FSR2_BUILD_AS_DLL)
    add_library(ffx_fsr2_api SHARED ${SOURCES})
else()
    add_library(ffx_fsr2_api STATIC ${SOURCES})
endif()

if(FFX_FSR2_API_DX12)
    message("Will build FSR2 library: DX12 backend")
    add_subdirectory(dx12)
endif()

if(FFX_FSR2_API_VK)
    message("Will build FSR2 library: Vulkan backend")
    add_subdirectory(vk)
endif()

source_group("source" FILES ${SOURCES})
set_source_files_properties(${SHADERS} PROPERTIES HEADER_FILE_ONLY TRUE)

# Packaging
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)
file(WRITE ${CMAKE_BINARY_DIR}/config.cmake.in [=[
@PACKAGE_INIT@
include(${CMAKE_CURRENT_LIST_DIR}/fsr2-targets.cmake)
check_required_components(ffx_fsr2_api)
]=])

if(WITH_VOLK)
    file(APPEND ${CMAKE_BINARY_DIR}/config.cmake.in [=[
find_package(volk CONFIG REQUIRED)
]=])
endif()

configure_package_config_file(${CMAKE_BINARY_DIR}/config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/fsr2-config.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_DATADIR}/fsr2
    NO_SET_AND_CHECK_MACRO)
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/fsr2-config-version.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion)
install(
    FILES
    ${CMAKE_CURRENT_BINARY_DIR}/fsr2-config.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/fsr2-config-version.cmake
    DESTINATION
    ${CMAKE_INSTALL_DATADIR}/fsr2)
install(TARGETS ffx_fsr2_api ffx_fsr2_api_vk EXPORT fsr2-targets)
install(EXPORT fsr2-targets DESTINATION ${CMAKE_INSTALL_DATADIR}/fsr2 NAMESPACE fsr2::)
# TODO: Install only the files that are necessary:
#   ffx_assert.h
#   ffx_error.h
#   ffx_util.h
#   ffx_types.h
#   ffx_fsr2.h
#   ffx_fsr2_interface.h
#   ffx_fsr2_common.h
#   ffx_fsr2_resources.h
install(DIRECTORY ${PROJECT_SOURCE_DIR} TYPE INCLUDE FILES_MATCHING PATTERN "*.h")
]==])

if(WITH_VOLK)
    file(READ "${SOURCE_PATH}/src/ffx-fsr2-api/vk/ffx_fsr2_vk.h" ffx_fsr2_vk)
    string(REGEX REPLACE "pragma once" "pragma once\n#include <volk.h>\n#define VK_NO_PROTOTYPES" ffx_fsr2_vk "${ffx_fsr2_vk}")
    file(WRITE "${SOURCE_PATH}/src/ffx-fsr2-api/vk/ffx_fsr2_vk.h" "${ffx_fsr2_vk}")
    list(APPEND FSR2_DEFINES "-DWITH_VOLK=true")
endif()

file(WRITE "${SOURCE_PATH}/src/ffx-fsr2-api/vk/CMakeLists.txt" [==[
if(NOT ${FFX_FSR2_API_VK})
    return()
endif()

file(GLOB_RECURSE VK "${CMAKE_CURRENT_SOURCE_DIR}/../ffx_assert.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/*.h" "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp")
find_package(Vulkan REQUIRED)

if(FSR2_BUILD_AS_DLL)
    add_library(ffx_fsr2_api_vk SHARED ${VK})
    target_link_libraries(ffx_fsr2_api_vk PUBLIC Vulkan::Vulkan)
else()
    add_library(ffx_fsr2_api_vk STATIC ${VK})
endif()

target_include_directories(ffx_fsr2_api_vk PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/../shaders/vk>)
target_include_directories(ffx_fsr2_api_vk PUBLIC ${Vulkan_INCLUDE_DIR})

file(DOWNLOAD "https://github.com/GabeRundlett/fsr2-precompiled-shaders/archive/refs/tags/0.1.0.zip" "${CMAKE_CURRENT_BINARY_DIR}/shaders.zip")
file(ARCHIVE_EXTRACT INPUT "${CMAKE_CURRENT_BINARY_DIR}/shaders.zip" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/..")
file(COPY "${CMAKE_CURRENT_BINARY_DIR}/../fsr2-precompiled-shaders-0.1.0/shaders" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/..")
file(REMOVE_RECURSE "${CMAKE_CURRENT_BINARY_DIR}/../fsr2-precompiled-shaders-0.1.0")
]==])

if(WITH_DX12)
    list(APPEND FSR2_DEFINES "-DFFX_FSR2_API_DX12=ON")
    list(APPEND FSR2_DEFINES "-DFFX_FSR2_API_VK=OFF")
endif()

if(WITH_VULKAN)
    list(APPEND FSR2_DEFINES "-DFFX_FSR2_API_DX12=OFF")
    list(APPEND FSR2_DEFINES "-DFFX_FSR2_API_VK=ON")
endif()

vcpkg_configure_cmake(
    SOURCE_PATH "${SOURCE_PATH}/src/ffx-fsr2-api"
    PREFER_NINJA
    OPTIONS ${FSR2_DEFINES}
)

vcpkg_install_cmake()
vcpkg_fixup_cmake_targets()
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/include/ffx-fsr2-api/bin/ffx_fsr2_api")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/include/ffx-fsr2-api/bin")
file(INSTALL "${SOURCE_PATH}/LICENSE.txt"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
