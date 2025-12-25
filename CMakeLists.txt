cmake_minimum_required(VERSION 4.2)

project(
    "imgui"
    VERSION 1.92.5
    LANGUAGES C CXX
)

# ------------------------
# Set compiler standards
# ------------------------
# Use C23 and C++23 for modern features, ensure strict compliance
set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable generation of compile_commands.json for IDEs and clangd
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ------------------------
# Default build type
# ------------------------
# Set to Debug if not specified to avoid empty configuration
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Choose the build type (Debug or Release)" FORCE)
endif()

# ------------------------
# Compiler flags
# ------------------------
# Sanitizers for debugging memory issues
# set(SANITIZER_FLAGS "-fsanitize=address -fsanitize=undefined -fsanitize-address-use-after-scope")

# Debug flags: disable optimization, enable warnings, sanitizers, frame pointer for stack traces
# set(DEBUG_FLAGS "-g -O0 -Wall -Werror -Wextra -fno-omit-frame-pointer ${SANITIZER_FLAGS}")

# Release flags: maximum optimization, LTO, remove debug info, fast math, static linking
# set(RELEASE_FLAGS "-static -O3 -march=native -mtune=native -flto -funroll-loops -fomit-frame-pointer -ffast-math -finline-functions -fdata-sections -ffunction-sections -Os -DNDEBUG -fno-stack-protector -fno-unwind-tables -fno-asynchronous-unwind-tables -g0")

# Apply flags to C and C++ for both Debug and Release
# set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${DEBUG_FLAGS}")
# set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${DEBUG_FLAGS}")
# set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} ${RELEASE_FLAGS}")
# set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${RELEASE_FLAGS}")

# Linker flags for Release: strip symbols and garbage-collect unused sections
# set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} -s -Wl,--gc-sections -Wl,--strip-all -Wl,--as-needed")

# Enable interprocedural optimization (LTO)
# set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)

# ------------------------
# CCACHE support
# ------------------------
# Speed up rebuilds by using ccache if available
find_program(CCACHE_PROGRAM "ccache")
if(CCACHE_PROGRAM)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
    set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK "${CCACHE_PROGRAM}")
endif()

# ------------------------
# ImGui backend configuration
# ------------------------
# Users can select comma-separated backends (e.g., bgfx, opengl)
set(IMGUI_BACKEND "" CACHE STRING "Comma-separated ImGui backends to use")
string(REPLACE "," ";" IMGUI_BACKEND_LIST "${IMGUI_BACKEND}")

# Initialize backend lists
set("IMGUI_BACKEND_SRC_FILES" "")
set("IMGUI_BACKEND_INCLUDE_DIRS" "")
set("IMGUI_BACKEND_LINK_LIBRARIES" "")

# Warn if no backend is specified
if(IMGUI_BACKEND STREQUAL "")
    message(WARNING "No ImGui backend specified. Are you sure this is intentional?")
endif()

# Supported backends
set(
    "IMGUI_BACKEND_SUPPORT_LIST" 
    "bgfx"
    "sdl3"
)

# Function to enable backend if supported
# Collects source files, include directories, and linker libraries
function(if_imgui_backend backend backend_support)
    if(backend STREQUAL backend_support)
        message(STATUS "ImGui backend '${backend_support}': ENABLED")

        # Grab all cpp files from the backend folder
        file(GLOB_RECURSE IMGUI_BACKEND_FILES "${CMAKE_CURRENT_LIST_DIR}/src/backends/${backend_support}/*.cpp")
        list(APPEND IMGUI_BACKEND_SRC_FILES ${IMGUI_BACKEND_FILES})

        # Add include directory for backend headers
        list(
            APPEND 
            IMGUI_BACKEND_INCLUDE_DIRS 
            "${CMAKE_CURRENT_LIST_DIR}/include/backends/${backend_support}"
        )

        # Export collected backend info to parent scope
        set(IMGUI_BACKEND_SRC_FILES "${IMGUI_BACKEND_SRC_FILES}" PARENT_SCOPE)
        set(IMGUI_BACKEND_INCLUDE_DIRS "${IMGUI_BACKEND_INCLUDE_DIRS}" PARENT_SCOPE)
        set(IMGUI_BACKEND_FOUND TRUE PARENT_SCOPE)

        message(STATUS "Added ImGui ${backend_support} backend")
    endif()
endfunction()

# ------------------------
# Enable selected backends
# ------------------------
foreach(backend IN LISTS IMGUI_BACKEND_LIST)
    set(IMGUI_BACKEND_FOUND FALSE)

    foreach(supported_backend IN LISTS IMGUI_BACKEND_SUPPORT_LIST)
        # If backend requires an external library, find it
        if(backend STREQUAL "bgfx")
            find_package(bgfx CONFIG REQUIRED)
            list(APPEND IMGUI_BACKEND_LINK_LIBRARIES "bgfx::bgfx")
        endif()

        if(backend STREQUAL "sdl3")
            find_package(SDL3 CONFIG REQUIRED)
            list(APPEND IMGUI_BACKEND_LINK_LIBRARIES "SDL3::SDL3")
        endif()

        # Check if this backend is supported and include its files
        if_imgui_backend(${backend} ${supported_backend})
    endforeach()

    # Warn if backend is unsupported
    if(NOT IMGUI_BACKEND_FOUND)
        message(WARNING "ImGui backend '${backend}': NOT SUPPORTED")
    endif()
endforeach()

# Debug output of backend files
message(STATUS "ImGui backend source files: ${IMGUI_BACKEND_SRC_FILES}")
message(STATUS "ImGui backend include dirs: ${IMGUI_BACKEND_INCLUDE_DIRS}")

# ------------------------
# Core ImGui sources
# ------------------------
file(GLOB_RECURSE "IMGUI_SRC_FILES" "${CMAKE_CURRENT_LIST_DIR}/src/imgui/*.cpp")

set(
    "IMGUI_INCLUDE_DIR" 
    "${CMAKE_CURRENT_LIST_DIR}/include/imgui"
    ${IMGUI_BACKEND_INCLUDE_DIRS}
)

set("IMGUI_INCLUDE_DIR_GENERATOR_EXPRESSION" "")
    
foreach(INCLUDE_DIR IN LISTS IMGUI_INCLUDE_DIR)
    list(APPEND IMGUI_INCLUDE_DIR_GENERATOR_EXPRESSION $<BUILD_INTERFACE:${INCLUDE_DIR}> )
endforeach()

list(APPEND IMGUI_INCLUDE_DIR_GENERATOR_EXPRESSION $<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/include> )

set("IMGUI_SRC_FILES" ${IMGUI_SRC_FILES} ${IMGUI_BACKEND_SRC_FILES})
set("IMGUI_LINK_LIBRARIES" ${IMGUI_BACKEND_LINK_LIBRARIES})

# ------------------------
# Build library
# ------------------------
set("IMGUI" "imgui")
if(IMGUI_BUILD_SHARED)
    add_library(${IMGUI} SHARED ${IMGUI_SRC_FILES})
    target_compile_definitions(${IMGUI} PRIVATE IMGUI_BUILD_SHARED)
else()
    add_library(${IMGUI} STATIC ${IMGUI_SRC_FILES})
endif()
target_include_directories(${IMGUI} PUBLIC ${IMGUI_INCLUDE_DIR_GENERATOR_EXPRESSION})
target_link_libraries(${IMGUI} PRIVATE ${IMGUI_LINK_LIBRARIES})

# ------------------------
# Installation rules
# ------------------------
# Install static/shared libraries and headers
install(
    TARGETS ${IMGUI}
    EXPORT ${IMGUI}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
    LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
    RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/bin
)

install(EXPORT ${IMGUI}
    FILE ${IMGUI}.cmake
    NAMESPACE imgui::
    DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/cmake/imgui
)

# Collect all header files for installation
set(IMGUI_ALL_HEADERS "")
foreach(DIR IN LISTS IMGUI_INCLUDE_DIR)
    file(GLOB_RECURSE HEADERS "${DIR}/*.h")
    list(APPEND IMGUI_ALL_HEADERS ${HEADERS})
endforeach()

install(FILES ${IMGUI_ALL_HEADERS} DESTINATION ${CMAKE_INSTALL_PREFIX}/include/imgui)

# Configure the package configuration file
include(CMakePackageConfigHelpers)

configure_package_config_file(
    "${CMAKE_CURRENT_LIST_DIR}/cmake/imguiConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake/imguiConfig.cmake"
    INSTALL_DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/cmake/imgui
)

# Generate a package version file
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/cmake/imguiConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

# Install the generated config and version files
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/cmake/imguiConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake/imguiConfigVersion.cmake"
    DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/cmake/imgui
)

# Install LICENSE
install(FILES "LICENSE.txt" DESTINATION ${CMAKE_INSTALL_PREFIX})