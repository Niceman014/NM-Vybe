cmake_minimum_required(VERSION 3.14)
project(nm_vybe LANGUAGES CXX)

# Flutter exposes a Profile configuration on Windows for AOT performance
# measurements. Visual Studio otherwise generates only its default configs.
set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release" CACHE STRING "" FORCE)

# Suppress MSVC experimental coroutine deprecation error for plugins
add_compile_definitions(_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)

# Compatibility macro for older plugins like isar
macro(apply_standard_settings target)
  target_compile_features(${target} PRIVATE cxx_std_17)
  set_target_properties(${target} PROPERTIES
    CXX_STANDARD_REQUIRED ON
  )
endmacro()

set(BINARY_NAME "nm_vybe")

# Define build standard
option(BUILD_SHARED_LIBS "Build shared libraries" ON)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Flutter plugins use the wide-character Win32 APIs.
add_definitions(-DUNICODE -D_UNICODE)

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

# Flutter-managed subdirectories
add_subdirectory(flutter)
add_subdirectory(runner)

# Generated plugin registration links plugins to the runner target, so include
# it only after runner/CMakeLists.txt has created that target.
include(${FLUTTER_MANAGED_DIR}/generated_plugins.cmake)

# Flutter's build command invokes the CMake INSTALL target to assemble the
# runnable Windows bundle. Keep the support files beside the runner executable.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "" FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)
install(FILES "${FLUTTER_ICU_DATA_FILE}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)
install(FILES "${FLUTTER_LIBRARY}"
  DESTINATION "${INSTALL_BUNDLE_LIB_DIR}" COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}" COMPONENT Runtime)
endif()

set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/windows/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
  DESTINATION "${INSTALL_BUNDLE_LIB_DIR}" COMPONENT Runtime)

set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")"
  COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

install(FILES "${AOT_LIBRARY}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  CONFIGURATIONS Profile;Release COMPONENT Runtime)
