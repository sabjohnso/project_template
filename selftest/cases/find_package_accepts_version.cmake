include(${CMAKE_CURRENT_LIST_DIR}/../lib/selftest.cmake)

# Issue 3: a consumer must request a version of the installed package.
# This case generates, builds, and installs a project at version 0.1.0.
# Then it configures one consumer project for each requested version.
# Version 0.1 must pass. Versions 0.2 and 1.0 must fail, because a 0.x
# project can change its interface at each minor version.

selftest_generate_project(versioned project_dir)
selftest_build_project(${project_dir} ${WORK_DIR}/build)
selftest_install_project(${WORK_DIR}/build ${WORK_DIR}/prefix)

# Write a consumer project that requests <version> of the package.
# Set <out_var> to the directory of the consumer project.
function(write_versioned_consumer version out_var)
  set(consumer_dir ${WORK_DIR}/consumer-${version})
  file(WRITE ${consumer_dir}/CMakeLists.txt
    "cmake_minimum_required(VERSION 3.21)\n"
    "project(consumer LANGUAGES CXX)\n"
    "find_package(versioned ${version} REQUIRED)\n")
  set(${out_var} ${consumer_dir} PARENT_SCOPE)
endfunction()

# Configure a consumer project that requests <version>.
# Set <result_var> to the result and <output_var> to the output.
function(consume_version version result_var output_var)
  write_versioned_consumer(${version} consumer_dir)
  selftest_consume_project(${consumer_dir} ${WORK_DIR}/build-${version}
    ${WORK_DIR}/prefix RESULT_VARIABLE rv OUTPUT_VARIABLE out)
  set(${result_var} "${rv}" PARENT_SCOPE)
  set(${output_var} "${out}" PARENT_SCOPE)
endfunction()


# The rule of the installed version file: the installed version X.Y.Z
# accepts the requested version A.B[.C] only when A equals X, B equals Y,
# and A.B[.C] is not greater than X.Y.Z.
# This part loads the installed version file in this script for each
# requested version in a grid. The grid has the boundary values.
set(version_file
  ${WORK_DIR}/prefix/lib/cmake/versioned-0.1.0/versioned-config-version.cmake)
selftest_assert_exists(${version_file})

# Set <out_var> to the decision of the version file for <requested>.
function(version_file_accepts requested out_var)
  string(REPLACE "." ";" parts "${requested}")
  list(LENGTH parts PACKAGE_FIND_VERSION_COUNT)
  list(APPEND parts 0 0 0)
  list(GET parts 0 PACKAGE_FIND_VERSION_MAJOR)
  list(GET parts 1 PACKAGE_FIND_VERSION_MINOR)
  list(GET parts 2 PACKAGE_FIND_VERSION_PATCH)
  set(PACKAGE_FIND_VERSION_TWEAK 0)
  set(PACKAGE_FIND_VERSION "${requested}")
  include(${version_file})
  set(${out_var} "${PACKAGE_VERSION_COMPATIBLE}" PARENT_SCOPE)
endfunction()

# Set <out_var> to the decision that the rule gives for <requested>
# and <installed>.
function(rule_accepts requested installed out_var)
  string(REPLACE "." ";" req "${requested}")
  string(REPLACE "." ";" ins "${installed}")
  list(GET req 0 req_major)
  list(GET req 1 req_minor)
  list(GET ins 0 ins_major)
  list(GET ins 1 ins_minor)
  if(req_major EQUAL ins_major AND req_minor EQUAL ins_minor
      AND requested VERSION_LESS_EQUAL installed)
    set(${out_var} TRUE PARENT_SCOPE)
  else()
    set(${out_var} FALSE PARENT_SCOPE)
  endif()
endfunction()

set(installed_version 0.1.0)
foreach(major 0 1)
  foreach(minor 0 1 2)
    foreach(patch "" 0 1)
      set(requested ${major}.${minor})
      if(NOT patch STREQUAL "")
        string(APPEND requested .${patch})
      endif()
      version_file_accepts(${requested} actual)
      rule_accepts(${requested} ${installed_version} expected)
      if(actual)
        set(actual TRUE)
      else()
        set(actual FALSE)
      endif()
      selftest_assert_equal("${actual}" "${expected}"
        "The version file must follow the rule for request ${requested}")
    endforeach()
  endforeach()
endforeach()

consume_version(0.1 rv out)
selftest_assert_equal("${rv}" "0"
  "find_package must accept version 0.1. Output:\n${out}")

# The consumer for version 0.1 passes. Thus a failure of the same
# consumer for a different version comes from the version check.
consume_version(0.2 rv out)
selftest_assert_matches("${rv}" "^[1-9]"
  "find_package must refuse version 0.2")

consume_version(1.0 rv out)
selftest_assert_matches("${rv}" "^[1-9]"
  "find_package must refuse version 1.0")
