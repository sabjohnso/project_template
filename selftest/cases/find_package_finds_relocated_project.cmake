include(${CMAKE_CURRENT_LIST_DIR}/../lib/selftest.cmake)

# Issue 2: the installed package must be relocatable.
# This case installs a project to one prefix and copies the install tree
# to a different directory. Then it removes the first prefix, so that a
# path to the first prefix cannot help. A consumer project must find the
# package in the new directory.

selftest_generate_project(movable project_dir)
selftest_build_project(${project_dir} ${WORK_DIR}/build)
selftest_install_project(${WORK_DIR}/build ${WORK_DIR}/first-prefix)

file(COPY ${WORK_DIR}/first-prefix/ DESTINATION ${WORK_DIR}/moved-prefix)
file(REMOVE_RECURSE ${WORK_DIR}/first-prefix)

set(consumer_dir ${WORK_DIR}/consumer)
file(WRITE ${consumer_dir}/CMakeLists.txt [=[
cmake_minimum_required(VERSION 3.21)
project(consumer LANGUAGES CXX)
find_package(movable REQUIRED)
add_executable(consumer main.cpp)
target_link_libraries(consumer PRIVATE movable::header)
]=])
file(WRITE ${consumer_dir}/main.cpp [=[
#include <movable/config.hpp>
int main() { return 0; }
]=])

selftest_consume_project(${consumer_dir} ${WORK_DIR}/consumer-build
  ${WORK_DIR}/moved-prefix BUILD)
