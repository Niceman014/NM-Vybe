cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

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

# --- CRITICAL: MUST INCLUDE THIS SO PLUGIN PATHS RESOLVE CORRECTLY ---
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
include(${FLUTTER_MANAGED_DIR}/generated_plugins.cmake)
# ----------------------------------------------------------------------

# Flutter-managed subdirectories
add_subdirectory(flutter)
add_subdirectory(runner)