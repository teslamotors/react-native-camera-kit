# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

cmake_minimum_required(VERSION 3.13)
set(CMAKE_VERBOSE_MAKEFILE on)

file(GLOB react_codegen_SRCS CONFIGURE_DEPENDS *.cpp react/renderer/components/rncamerakit_specs/*.cpp)

add_library(
  react_codegen_rncamerakit_specs
  OBJECT
  ${react_codegen_SRCS}
)

target_include_directories(react_codegen_rncamerakit_specs PUBLIC . react/renderer/components/rncamerakit_specs)

target_link_libraries(
  react_codegen_rncamerakit_specs
  fbjni
  jsi
  # We need to link different libraries based on whether we are building rncore or not, that's necessary
  # because we want to break a circular dependency between react_codegen_rncore and reactnative
  reactnative
)

# Fix crash on startup on RN 0.81 or newer due to broken codegen (it always uses target_compile_options)
# Do not commit the change where the if-statement is removed unless they fix Codegen
# See https://github.com/software-mansion/react-native-screens/pull/3114/commits/b4d283c8fc65e36ec60726fd7513735ccc7e1fe9
# See https://github.com/react-native-maps/react-native-maps/issues/5699
# (commit https://github.com/react-native-maps/react-native-maps/commit/c587f30b8499b79a2266687c641bfed10b3ecc2c)
if(ReactAndroid_VERSION_MINOR GREATER_EQUAL 80)
  target_compile_reactnative_options(react_codegen_rncamerakit_specs PRIVATE)
else()
  target_compile_options(
    react_codegen_rncamerakit_specs
    PRIVATE
    -DLOG_TAG=\"ReactNative\"
    -fexceptions
    -frtti
    -std=c++20
    -Wall
  )
endif()
