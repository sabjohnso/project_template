include(${CMAKE_CURRENT_LIST_DIR}/../lib/selftest.cmake)

# Issue 2: a consumer must find the installed package with find_package.
# This case generates, builds, and installs a project. Then it builds a
# consumer project that links the header target of the package.

selftest_generate_project(findme project_dir)
selftest_build_project(${project_dir} ${WORK_DIR}/build)
selftest_install_project(${WORK_DIR}/build ${WORK_DIR}/prefix)

set(consumer_dir ${WORK_DIR}/consumer)
file(WRITE ${consumer_dir}/CMakeLists.txt [=[
cmake_minimum_required(VERSION 3.21)
project(consumer LANGUAGES CXX)
find_package(findme REQUIRED)
add_executable(consumer main.cpp)
target_link_libraries(consumer PRIVATE findme::header)
]=])
file(WRITE ${consumer_dir}/main.cpp [=[
#include <findme/config.hpp>
int main() { return 0; }
]=])

selftest_consume_project(${consumer_dir} ${WORK_DIR}/consumer-build
  ${WORK_DIR}/prefix BUILD)
