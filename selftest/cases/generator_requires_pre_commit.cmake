include(${CMAKE_CURRENT_LIST_DIR}/../lib/selftest.cmake)

# Issue 6: the generator must stop before it writes a file when the
# pre-commit tool is not available.
# This case runs the generator with a PATH that has git but does not
# have pre-commit.

set(search_path /usr/bin:/bin)
find_program(pre_commit_on_search_path pre-commit
  PATHS /usr/bin /bin NO_DEFAULT_PATH)
if(pre_commit_on_search_path)
  selftest_fail("This case needs a PATH without pre-commit: ${search_path}")
endif()

set(project_dir ${WORK_DIR}/nohook)
file(MAKE_DIRECTORY ${project_dir})

selftest_run_capture(rv out
  WORKING_DIRECTORY ${project_dir}
  COMMAND ${CMAKE_COMMAND} -E env PATH=${search_path}
    ${CMAKE_COMMAND} -P ${TEMPLATE_DIR}/generate.cmake)

selftest_assert_matches("${rv}" "^[1-9]"
  "The generator must fail when pre-commit is not available")
# Make sure that the missing pre-commit caused the failure, and not a
# missing git.
selftest_assert_matches("${out}" "PRE_COMMIT_EXECUTABLE"
  "The failure must come from the search for pre-commit")

file(GLOB entries LIST_DIRECTORIES true ${project_dir}/* ${project_dir}/.*)
selftest_assert_equal("${entries}" ""
  "The generator must not write a file when pre-commit is not available")
