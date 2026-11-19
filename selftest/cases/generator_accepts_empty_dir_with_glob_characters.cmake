include(${CMAKE_CURRENT_LIST_DIR}/../lib/selftest.cmake)

# Issue 5: the generator must accept each empty output directory, also
# when its name has glob characters.
# A sibling directory "axb" has a file. If the generator reads "*" or
# "?" in a name as a pattern, the pattern also finds the file in "axb".
# Then the generator refuses an empty directory by mistake.

file(WRITE ${WORK_DIR}/axb/user.txt "user text\n")

foreach(name "a*b" "a?b" "a]b" "a[x]b")
  set(project_dir "${WORK_DIR}/${name}")
  file(MAKE_DIRECTORY "${project_dir}")
  # selftest_run_capture loses its COMMAND argument when a path has an
  # unmatched "]". Thus this case calls execute_process directly.
  execute_process(
    COMMAND ${CMAKE_COMMAND} -P ${TEMPLATE_DIR}/generate.cmake
    WORKING_DIRECTORY "${project_dir}"
    OUTPUT_VARIABLE out
    ERROR_VARIABLE out)
  selftest_assert_not_matches("${out}" "output directory is not empty"
    "The generator must accept the empty directory '${name}'")
endforeach()
