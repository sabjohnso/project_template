include(${CMAKE_CURRENT_LIST_DIR}/../lib/selftest.cmake)

# Issue 5: the generator must refuse each output directory that is not
# empty. It must not change an entry in that directory.
# This case tries each start state in each directory name below.
# A name with glob characters ("br[ab]") must not hide the entries.

set(start_states only_dotfile only_subdirectory only_plain_file)
set(directory_names plain "br[ab]")

# Put the entries of <state> into the new directory <dir>.
function(make_start_state state dir)
  file(MAKE_DIRECTORY "${dir}")
  if(state STREQUAL "only_dotfile")
    file(WRITE "${dir}/.user" "user text\n")
  elseif(state STREQUAL "only_subdirectory")
    file(MAKE_DIRECTORY "${dir}/user_dir")
  elseif(state STREQUAL "only_plain_file")
    file(WRITE "${dir}/user.txt" "user text\n")
  else()
    selftest_fail("Unknown start state: ${state}")
  endif()
endfunction()

# Set <out_var> to a list of each entry below <root> and the hash of
# each file. The glob pattern starts with <root>, which has no glob
# characters, so the directory name below <root> is not a pattern.
function(snapshot root out_var)
  file(GLOB_RECURSE entries LIST_DIRECTORIES true RELATIVE "${root}"
    "${root}/*")
  set(snapshot "")
  foreach(entry IN LISTS entries)
    set(hash "directory")
    if(NOT IS_DIRECTORY "${root}/${entry}")
      file(SHA256 "${root}/${entry}" hash)
    endif()
    string(APPEND snapshot "${entry}=${hash}\n")
  endforeach()
  set(${out_var} "${snapshot}" PARENT_SCOPE)
endfunction()

# Run the generator in a directory with the start state <state>.
# The directory has the name <name>.
function(check_refusal state name)
  string(MAKE_C_IDENTIFIER "${state}-${name}" root_name)
  set(root "${WORK_DIR}/${root_name}")
  set(dir "${root}/${name}")
  make_start_state(${state} "${dir}")
  snapshot("${root}" before)

  selftest_run_capture(rv out
    WORKING_DIRECTORY "${dir}"
    COMMAND ${CMAKE_COMMAND} -P ${TEMPLATE_DIR}/generate.cmake)

  selftest_assert_matches("${rv}" "^[1-9]"
    "The generator must fail in '${name}' with ${state}. Output:\n${out}")
  snapshot("${root}" after)
  selftest_assert_equal("${after}" "${before}"
    "The generator must not change '${name}' with ${state}")
endfunction()

foreach(name IN LISTS directory_names)
  foreach(state IN LISTS start_states)
    check_refusal(${state} "${name}")
  endforeach()
endforeach()
