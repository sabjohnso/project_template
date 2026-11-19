# Version 3.19 is necessary for COMMAND_ERROR_IS_FATAL in execute_process.
cmake_minimum_required(VERSION 3.19)

# Find all external tools before the script writes a file.
find_package(Git REQUIRED)
find_program(PRE_COMMIT_EXECUTABLE pre-commit REQUIRED)

set(CMAKE_BOOTSTRAP_URL https://github.com/sabjohnso/cmake_utilities_boostrap.git)

get_filename_component(TEMPLATE_DIR ${CMAKE_SCRIPT_MODE_FILE} DIRECTORY)

set(OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR})
get_filename_component(NAME ${OUTPUT_DIR} NAME)

# Do not write into a directory that has entries.
# Thus a second run cannot change an existing project.
# The glob reads "[", "]", "*" and "?" in a path as pattern characters.
# Put each of these characters in brackets, so that the glob reads it
# as a literal character.
string(REGEX REPLACE "([][*?])" "[\\1]" output_dir_pattern "${OUTPUT_DIR}")
file(GLOB output_dir_entries LIST_DIRECTORIES true
  "${output_dir_pattern}/*" "${output_dir_pattern}/.*")
if(output_dir_entries)
  message(FATAL_ERROR
    "The output directory is not empty: ${OUTPUT_DIR}\n"
    "Run the generator in a new, empty directory.")
endif()

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
configure_file(${TEMPLATE_DIR}/test/unit/config_test.cpp.in ${OUTPUT_DIR}/test/unit/config_test.cpp @ONLY)
configure_file(${TEMPLATE_DIR}/test/feature/CMakeLists.txt.in ${OUTPUT_DIR}/test/feature/CMakeLists.txt @ONLY)
configure_file(${TEMPLATE_DIR}/Config.cmake.in.in ${OUTPUT_DIR}/${NAME}-config.cmake.in @ONLY)
configure_file(${TEMPLATE_DIR}/Dependencies.cmake.in ${OUTPUT_DIR}/cmake/${NAME}_deps.cmake COPYONLY)
configure_file(${TEMPLATE_DIR}/.pre-commit-config.yaml ${OUTPUT_DIR}/.pre-commit-config.yaml COPYONLY)
configure_file(${TEMPLATE_DIR}/initial-cache.cmake.in ${OUTPUT_DIR}/initial-cache.cmake @ONLY)
configure_file(${TEMPLATE_DIR}/sanitizing-cache.cmake.in ${OUTPUT_DIR}/sanitizing-cache.cmake @ONLY)
configure_file(${TEMPLATE_DIR}/.clang-format ${OUTPUT_DIR}/.clang-format)
configure_file(${TEMPLATE_DIR}/CMakePresets.json ${OUTPUT_DIR}/CMakePresets.json @ONLY)

# Run one command in the output directory.
# Stop the generator when the command fails. Each step below goes
# through this function, so each step stops the generator on failure.
function(run_in_output_dir)
  execute_process(
    COMMAND ${ARGN}
    WORKING_DIRECTORY ${OUTPUT_DIR}
    COMMAND_ERROR_IS_FATAL ANY)
endfunction()

run_in_output_dir(${GIT_EXECUTABLE} init)
run_in_output_dir(${PRE_COMMIT_EXECUTABLE} install)
run_in_output_dir(${GIT_EXECUTABLE} add .)
run_in_output_dir(${GIT_EXECUTABLE} commit -m "First import")
run_in_output_dir(${GIT_EXECUTABLE} submodule add ${CMAKE_BOOTSTRAP_URL} cmake_utilities)
run_in_output_dir(${GIT_EXECUTABLE} add .)
run_in_output_dir(${GIT_EXECUTABLE} commit -m "Add cmake_utilities submodule")
