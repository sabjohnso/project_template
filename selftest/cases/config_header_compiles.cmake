include(${CMAKE_CURRENT_LIST_DIR}/../lib/selftest.cmake)

# Issue 1: the generated config.hpp must compile.
# The generated project must contain a unit test named "config".
# This test includes <NAME/config.hpp>. It must compile and pass.

selftest_generate_project(cfgdemo project_dir)
selftest_build_project(${project_dir} ${WORK_DIR}/build)

selftest_run_capture(rv out
  COMMAND ${CMAKE_CTEST_COMMAND} --test-dir ${WORK_DIR}/build -R "^config$"
          --no-tests=error --output-on-failure)

selftest_assert_equal("${rv}" "0"
  "the config unit test must exist and pass. Output:\n${out}")
selftest_assert_matches("${out}" "config \\.+ +Passed"
  "the ctest output must show that the config test passed")
