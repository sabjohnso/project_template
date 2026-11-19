# Smoke case: generate a project, then configure and build it.
# This case records the current behavior of the generator.
include(${CMAKE_CURRENT_LIST_DIR}/../lib/selftest.cmake)

selftest_generate_project(smoke project_dir)
selftest_build_project(${project_dir} ${WORK_DIR}/build)
selftest_assert_exists(${WORK_DIR}/build/CMakeCache.txt)
