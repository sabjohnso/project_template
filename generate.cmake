cmake_minimum_required(VERSION 3.12)

find_package(Git REQUIRED)

set(CMAKE_BOOTSTRAP_URL https://github.com/sabjohnso/cmake_utilities_boostrap.git)

get_filename_component(TEMPLATE_DIR ${CMAKE_SCRIPT_MODE_FILE} DIRECTORY)

set(OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR})
get_filename_component(NAME ${OUTPUT_DIR} NAME)
file(MAKE_DIRECTORY
  ${OUTPUT_DIR}/src/include/${NAME}
  ${OUTPUT_DIR}/src/lib
  ${OUTPUT_DIR}/src/bin
  ${OUTPUT_DIR}/test/unit
  ${OUTPUT_DIR}/test/feature
  ${OUTPUT_DIR}/cmake)

configure_file(${TEMPLATE_DIR}/gitignore.in ${OUTPUT_DIR}/.gitignore COPYONLY)
configure_file(${TEMPLATE_DIR}/TopLevel.cmake.in ${OUTPUT_DIR}/CMakeLists.txt @ONLY)
configure_file(${TEMPLATE_DIR}/src/CMakeLists.txt.in ${OUTPUT_DIR}/src/CMakeLists.txt @ONLY)
configure_file(${TEMPLATE_DIR}/src/include/CMakeLists.txt.in ${OUTPUT_DIR}/src/include/CMakeLists.txt @ONLY)
configure_file(${TEMPLATE_DIR}/src/include/name/CMakeLists.txt.in ${OUTPUT_DIR}/src/include/${NAME}/CMakeLists.txt @ONLY)
configure_file(${TEMPLATE_DIR}/src/lib/CMakeLists.txt.in ${OUTPUT_DIR}/src/lib/CMakeLists.txt @ONLY)
configure_file(${TEMPLATE_DIR}/src/bin/CMakeLists.txt.in ${OUTPUT_DIR}/src/bin/CMakeLists.txt @ONLY)
configure_file(${TEMPLATE_DIR}/src/config.hpp.in.in ${OUTPUT_DIR}/src/include/${NAME}/config.hpp.in @ONLY)
configure_file(${TEMPLATE_DIR}/test/CMakeLists.txt.in ${OUTPUT_DIR}/test/CMakeLists.txt @ONLY)
configure_file(${TEMPLATE_DIR}/test/unit/CMakeLists.txt.in ${OUTPUT_DIR}/test/unit/CMakeLists.txt @ONLY)
configure_file(${TEMPLATE_DIR}/test/feature/CMakeLists.txt.in ${OUTPUT_DIR}/test/feature/CMakeLists.txt @ONLY)
configure_file(${TEMPLATE_DIR}/Config.cmake.in.in ${OUTPUT_DIR}/${NAME}-config.cmake.in @ONLY)
configure_file(${TEMPLATE_DIR}/Dependencies.cmake.in ${OUTPUT_DIR}/cmake/${NAME}_deps.cmake COPYONLY)
configure_file(${TEMPLATE_DIR}/.pre-commit-config.yaml ${OUTPUT_DIR}/.pre-commit-config.yaml COPYONLY)
configure_file(${TEMPLATE_DIR}/initial-cache.cmake.in ${OUTPUT_DIR}/initial-cache.cmake @ONLY)
configure_file(${TEMPLATE_DIR}/sanitizing-cache.cmake.in ${OUTPUT_DIR}/sanitizing-cache.cmake @ONLY)
configure_file(${TEMPLATE_DIR}/.clang-format ${OUTPUT_DIR}/.clang-format)
configure_file(${TEMPLATE_DIR}/CMakePresets.json ${OUTPUT_DIR}/CMakePresets.json @ONLY)

execute_process(
  COMMAND ${GIT_EXECUTABLE} init
  WORKING_DIRECTORY ${OUTPUT_DIR})

execute_process(
  COMMAND pre-commit install
  WORKING_DIRECTORY ${OUTPUT_DIR})

execute_process(
  COMMAND ${GIT_EXECUTABLE} add .
  WORKING_DIRECTORY ${OUTPUT_DIR})

execute_process(
  COMMAND ${GIT_EXECUTABLE} commit -m "First import"
  WORKING_DIRECTORY ${OUTPUT_DIR})

execute_process(
  COMMAND ${GIT_EXECUTABLE} submodule add ${CMAKE_BOOTSTRAP_URL} cmake_utilities
  WORKING_DIRECTORY ${OUTPUT_DIR})

execute_process(
  COMMAND ${GIT_EXECUTABLE} add .
  WORKING_DIRECTORY ${OUTPUT_DIR})

execute_process(
  COMMAND ${GIT_EXECUTABLE} commit -m "Added cmake boostrap submodule"
  WORKING_DIRECTORY ${OUTPUT_DIR})
