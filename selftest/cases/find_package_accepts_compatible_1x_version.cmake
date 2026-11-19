include(${CMAKE_CURRENT_LIST_DIR}/../lib/selftest.cmake)

# Issue 3: after version 1.0, a minor version must not break the
# interface. Thus an installed 1.2.0 must accept a request for 1.0, and
# it must refuse a request for 2.0.
# This case changes the version of a generated project to 1.2.0 before
# the build.

selftest_generate_project(stable project_dir)

file(READ ${project_dir}/CMakeLists.txt top_level)
string(REPLACE "VERSION 0.1.0" "VERSION 1.2.0" top_level "${top_level}")
file(WRITE ${project_dir}/CMakeLists.txt "${top_level}")

selftest_build_project(${project_dir} ${WORK_DIR}/build)
selftest_install_project(${WORK_DIR}/build ${WORK_DIR}/prefix)

# Configure a consumer project that requests <version>.
# Set <result_var> to the result and <output_var> to the output.
function(consume_version version result_var output_var)
  set(consumer_dir ${WORK_DIR}/consumer-${version})
  file(WRITE ${consumer_dir}/CMakeLists.txt
    "cmake_minimum_required(VERSION 3.21)\n"
    "project(consumer LANGUAGES CXX)\n"
    "find_package(stable ${version} REQUIRED)\n")
  selftest_consume_project(${consumer_dir} ${WORK_DIR}/build-${version}
    ${WORK_DIR}/prefix RESULT_VARIABLE rv OUTPUT_VARIABLE out)
  set(${result_var} "${rv}" PARENT_SCOPE)
  set(${output_var} "${out}" PARENT_SCOPE)
endfunction()

consume_version(1.0 rv out)
selftest_assert_equal("${rv}" "0"
  "find_package must accept version 1.0 from 1.2.0. Output:\n${out}")

consume_version(2.0 rv out)
selftest_assert_matches("${rv}" "^[1-9]"
  "find_package must refuse version 2.0 from 1.2.0")
