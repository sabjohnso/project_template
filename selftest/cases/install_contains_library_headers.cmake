include(${CMAKE_CURRENT_LIST_DIR}/../lib/selftest.cmake)

# Issue 4: the install step must install the library headers.
# This case adds a header to a generated project. It builds and installs
# the project. Then it builds a consumer that includes the header.

selftest_generate_project(hdrs project_dir)
file(WRITE ${project_dir}/src/include/hdrs/hello.hpp [=[
#pragma once
namespace hdrs {
inline int hello() { return 42; }
}
]=])
selftest_build_project(${project_dir} ${WORK_DIR}/build)
selftest_install_project(${WORK_DIR}/build ${WORK_DIR}/prefix)

# The generated config.hpp must stay in the package.
# The template inputs of the source directory must not go in the package.
set(installed_dir ${WORK_DIR}/prefix/include/hdrs)
selftest_assert_exists(${installed_dir}/hello.hpp)
selftest_assert_exists(${installed_dir}/config.hpp)
foreach(unwanted config.hpp.in CMakeLists.txt)
  if(EXISTS ${installed_dir}/${unwanted})
    selftest_fail("The package must not contain ${unwanted}")
  endif()
endforeach()

set(consumer_dir ${WORK_DIR}/consumer)
file(WRITE ${consumer_dir}/CMakeLists.txt [=[
cmake_minimum_required(VERSION 3.21)
project(consumer LANGUAGES CXX)
find_package(hdrs REQUIRED)
add_executable(consumer main.cpp)
target_link_libraries(consumer PRIVATE hdrs::header)
]=])
file(WRITE ${consumer_dir}/main.cpp [=[
#include <hdrs/hello.hpp>
int main() { return hdrs::hello() == 42 ? 0 : 1; }
]=])

selftest_consume_project(${consumer_dir} ${WORK_DIR}/consumer-build
  ${WORK_DIR}/prefix BUILD)
