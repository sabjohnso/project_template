# Issue 5: a second run of the generator must not change an existing project.
include(${CMAKE_CURRENT_LIST_DIR}/../lib/selftest.cmake)

selftest_generate_project(rerun project_dir)

# Change a file that the generator writes.
set(changed_file ${project_dir}/test/unit/CMakeLists.txt)
set(user_text "# user change\n")
file(WRITE ${changed_file} "${user_text}")

# Add a new file that git does not track.
set(new_file ${project_dir}/test/unit/extra_test.cpp)
set(new_text "// user test\n")
file(WRITE ${new_file} "${new_text}")

selftest_run_capture(log_rv log_before
  WORKING_DIRECTORY ${project_dir}
  COMMAND git log --oneline)

# Run the generator again in the same directory.
selftest_run_capture(rv out
  WORKING_DIRECTORY ${project_dir}
  COMMAND ${CMAKE_COMMAND} -P ${TEMPLATE_DIR}/generate.cmake)
selftest_assert_matches("${rv}" "^[1-9]"
  "The generator must fail in a directory that is not empty")

file(READ ${changed_file} actual_text)
selftest_assert_equal("${actual_text}" "${user_text}"
  "The generator must not change the user file")

file(READ ${new_file} actual_new_text)
selftest_assert_equal("${actual_new_text}" "${new_text}"
  "The generator must not change the new user file")

selftest_run_capture(log_rv log_after
  WORKING_DIRECTORY ${project_dir}
  COMMAND git log --oneline)
selftest_assert_equal("${log_after}" "${log_before}"
  "The generator must not add a commit")
