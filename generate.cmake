cmake_minimum_required(VERSION 3.12)

find_package(Git REQUIRED)

set(CMAKE_BOOTSTRAP_URL https://github.com/sabjohnso/cmake_utilities_boostrap.git)

get_filename_component(TEMPLATE_DIR ${CMAKE_SCRIPT_MODE_FILE} DIRECTORY)

set(OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR})
get_filename_component(NAME ${OUTPUT_DIR} NAME)
set(SOURCE_DIR ${OUTPUT_DIR}/${NAME})
set(TESTING_DIR ${OUTPUT_DIR}/${NAME}_testing)
set(SCRIPTS_DIR ${OUTPUT_DIR}/scripts)

file(MAKE_DIRECTORY ${SOURCE_DIR} ${TESTING_DIR} ${OUTPUT_DIR}/cmake ${SCRIPTS_DIR})

configure_file(${TEMPLATE_DIR}/gitignore.in ${OUTPUT_DIR}/.gitignore COPYONLY)
configure_file(${TEMPLATE_DIR}/TopLevel.cmake.in ${OUTPUT_DIR}/CMakeLists.txt @ONLY)
configure_file(${TEMPLATE_DIR}/Source.cmake.in ${SOURCE_DIR}/CMakeLists.txt @ONLY)
configure_file(${TEMPLATE_DIR}/Testing.cmake.in ${TESTING_DIR}/CMakeLists.txt @ONLY)
configure_file(${TEMPLATE_DIR}/config.hpp.in.in ${SOURCE_DIR}/config.hpp.in @ONLY)
configure_file(${TEMPLATE_DIR}/Config.cmake.in.in ${OUTPUT_DIR}/${NAME}-config.cmake.in @ONLY)
configure_file(${TEMPLATE_DIR}/Dependencies.cmake.in ${OUTPUT_DIR}/cmake/${NAME}_deps.cmake COPYONLY)
configure_file(${TEMPLATE_DIR}/check-format.sh.in ${SCRIPTS_DIR}/check-format.sh @ONLY)
configure_file(${TEMPLATE_DIR}/format.sh.in ${SCRIPTS_DIR}/check-format.sh @ONLY)
configure_file(${TEMPLATE_DIR}/initial-cache.cmake.in ${OUTPUT_DIR}/initial-cache.cmake @ONLY)
configure_file(${TEMPLATE_DIR}/sanitizing-cache.cmake.in ${OUTPUT_DIR}/sanitizing-cache.cmake @ONLY)
configure_file(${TEMPLATE_DIR}/.clang-format ${OUTPUT_DIR}/.clang-format)
configure_file(${TEMPLATE_DIR}/CMakePresets.json ${OUTPUT_DIR}/CMakePresets.json @ONLY)

execute_process(
  COMMAND ${GIT_EXECUTABLE} init
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
