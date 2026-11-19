# Helper functions for the self-test cases.
#
# A case runs in script mode:
#   cmake -DTEMPLATE_DIR=<repo root> -DWORK_DIR=<work dir> -P <case file>
#
# A case includes this file first. The include does these steps:
#   1. It makes sure that TEMPLATE_DIR and WORK_DIR are set.
#   2. It removes WORK_DIR and makes it again, empty.
#
# Each function does one job. Each function that runs a command stops
# the case and shows the output of the command when the command fails.
include_guard(GLOBAL)

# ---------------------------------------------------------------------
# Public functions: the steps that a case uses
# ---------------------------------------------------------------------

# selftest_generate_project(<name> <out_var>)
#
# Make the new empty directory WORK_DIR/<name>. Run generate.cmake in
# that directory. Set <out_var> to the path of the generated project.
function(selftest_generate_project name out_var)
  set(project_dir "${WORK_DIR}/${name}")
  if(EXISTS "${project_dir}")
    selftest_fail("Directory for project '${name}' exists: ${project_dir}")
  endif()
  file(MAKE_DIRECTORY "${project_dir}")
  selftest_run("generate project '${name}'"
    WORKING_DIRECTORY "${project_dir}"
    COMMAND "${CMAKE_COMMAND}" -P "${TEMPLATE_DIR}/generate.cmake")
  set(${out_var} "${project_dir}" PARENT_SCOPE)
endfunction()

# selftest_build_project(<source_dir> <build_dir> [<cmake_arg>...])
#
# Configure the project in <source_dir> into <build_dir>, then build it.
# Pass each extra argument to the configure step.
function(selftest_build_project source_dir build_dir)
  selftest_configure("${source_dir}" "${build_dir}" ${ARGN})
  selftest_build("${build_dir}")
endfunction()

# selftest_install_project(<build_dir> <prefix>)
#
# Install the built project in <build_dir> into <prefix>.
function(selftest_install_project build_dir prefix)
  selftest_run("install '${build_dir}' into '${prefix}'"
    COMMAND "${CMAKE_COMMAND}" --install "${build_dir}" --prefix "${prefix}")
endfunction()

# selftest_consume_project(<source_dir> <build_dir> <prefix>
#                          [BUILD]
#                          [RESULT_VARIABLE <var> OUTPUT_VARIABLE <var>])
#
# Configure the consumer project in <source_dir> into <build_dir> with
# CMAKE_PREFIX_PATH set to <prefix>. With BUILD, also build it.
#
# Without RESULT_VARIABLE, stop the case when a step fails.
# With RESULT_VARIABLE, do not stop the case. Set the RESULT_VARIABLE
# to the exit code of the first step that fails, or to 0. Set the
# OUTPUT_VARIABLE to the output of all the steps that ran.
function(selftest_consume_project source_dir build_dir prefix)
  cmake_parse_arguments(PARSE_ARGV 3 arg
    "BUILD" "RESULT_VARIABLE;OUTPUT_VARIABLE" "")
  selftest_require_no_extra_args(selftest_consume_project arg)
  if(NOT arg_RESULT_VARIABLE)
    selftest_build_or_configure("${arg_BUILD}" "${source_dir}" "${build_dir}"
      "-DCMAKE_PREFIX_PATH=${prefix}")
    return()
  endif()
  selftest_try_consume("${arg_BUILD}" "${source_dir}" "${build_dir}"
    "${prefix}" result output)
  set(${arg_RESULT_VARIABLE} "${result}" PARENT_SCOPE)
  if(arg_OUTPUT_VARIABLE)
    set(${arg_OUTPUT_VARIABLE} "${output}" PARENT_SCOPE)
  endif()
endfunction()

# ---------------------------------------------------------------------
# Public functions: assertions
# ---------------------------------------------------------------------

# selftest_fail(<message>)
#
# Stop the case. Show <message>.
function(selftest_fail message)
  message(FATAL_ERROR "SELFTEST FAILURE: ${message}")
endfunction()

# selftest_assert_equal(<actual> <expected> <message>)
#
# Stop the case when the string <actual> is not equal to <expected>.
function(selftest_assert_equal actual expected message)
  if(NOT "${actual}" STREQUAL "${expected}")
    selftest_fail("${message}\n  expected: '${expected}'\n  actual:   '${actual}'")
  endif()
endfunction()

# selftest_assert_matches(<text> <regex> <message>)
#
# Stop the case when <text> does not match the regular expression <regex>.
function(selftest_assert_matches text regex message)
  if(NOT "${text}" MATCHES "${regex}")
    selftest_fail("${message}\n  regex: ${regex}\n  text:\n${text}")
  endif()
endfunction()

# selftest_assert_not_matches(<text> <regex> <message>)
#
# Stop the case when <text> matches the regular expression <regex>.
function(selftest_assert_not_matches text regex message)
  if("${text}" MATCHES "${regex}")
    selftest_fail("${message}\n  regex: ${regex}\n  text:\n${text}")
  endif()
endfunction()

# selftest_assert_exists(<path>)
#
# Stop the case when <path> does not exist.
function(selftest_assert_exists path)
  if(NOT EXISTS "${path}")
    selftest_fail("Path does not exist: ${path}")
  endif()
endfunction()

# ---------------------------------------------------------------------
# Public functions: command runners
# ---------------------------------------------------------------------

# selftest_run(<description> COMMAND <cmd>... [WORKING_DIRECTORY <dir>])
#
# Run one command. Stop the case and show the output when the command
# fails.
function(selftest_run description)
  selftest_run_capture(result output ${ARGN})
  if(NOT result EQUAL 0)
    selftest_fail("Cannot ${description} (result: ${result})\n${output}")
  endif()
endfunction()

# selftest_run_capture(<result_var> <output_var>
#                      COMMAND <cmd>... [WORKING_DIRECTORY <dir>])
#
# Run one command. Do not stop the case. Set <result_var> to the exit
# code (or an error string) and <output_var> to stdout and stderr.
function(selftest_run_capture result_var output_var)
  execute_process(${ARGN}
    RESULT_VARIABLE result
    OUTPUT_VARIABLE output
    ERROR_VARIABLE output)
  set(${result_var} "${result}" PARENT_SCOPE)
  set(${output_var} "${output}" PARENT_SCOPE)
endfunction()

# ---------------------------------------------------------------------
# Private functions
# ---------------------------------------------------------------------

# Configure <source_dir> into <build_dir>. Stop the case on failure.
function(selftest_configure source_dir build_dir)
  selftest_run("configure '${source_dir}'"
    COMMAND "${CMAKE_COMMAND}" -S "${source_dir}" -B "${build_dir}" ${ARGN})
endfunction()

# Build <build_dir>. Stop the case on failure.
function(selftest_build build_dir)
  selftest_run("build '${build_dir}'"
    COMMAND "${CMAKE_COMMAND}" --build "${build_dir}")
endfunction()

# Configure, and build when <do_build> is true. Stop the case on failure.
function(selftest_build_or_configure do_build source_dir build_dir)
  selftest_configure("${source_dir}" "${build_dir}" ${ARGN})
  if(do_build)
    selftest_build("${build_dir}")
  endif()
endfunction()

# Configure a consumer, and build it when <do_build> is true.
# Do not stop the case. Stop at the first step that fails.
function(selftest_try_consume do_build source_dir build_dir prefix
    result_var output_var)
  selftest_run_capture(result output
    COMMAND "${CMAKE_COMMAND}" -S "${source_dir}" -B "${build_dir}"
      "-DCMAKE_PREFIX_PATH=${prefix}")
  if(do_build AND result EQUAL 0)
    selftest_run_capture(result build_output
      COMMAND "${CMAKE_COMMAND}" --build "${build_dir}")
    string(APPEND output "${build_output}")
  endif()
  set(${result_var} "${result}" PARENT_SCOPE)
  set(${output_var} "${output}" PARENT_SCOPE)
endfunction()

# Stop the case when a call has arguments that it does not know.
function(selftest_require_no_extra_args function_name prefix)
  if(DEFINED ${prefix}_UNPARSED_ARGUMENTS)
    selftest_fail(
      "${function_name}: unknown arguments: ${${prefix}_UNPARSED_ARGUMENTS}")
  endif()
endfunction()

# Stop the case when the variable <name> is not an absolute path.
function(selftest_require_absolute_path name)
  if(NOT DEFINED ${name} OR NOT IS_ABSOLUTE "${${name}}")
    selftest_fail("Set ${name} to an absolute path with -D${name}=<path>")
  endif()
endfunction()

# Remove WORK_DIR and make it again, empty.
# Refuse a WORK_DIR that is the root directory or that contains
# TEMPLATE_DIR. This prevents the removal of the template.
function(selftest_reset_work_dir)
  get_filename_component(work_dir "${WORK_DIR}" REALPATH)
  get_filename_component(template_dir "${TEMPLATE_DIR}" REALPATH)
  string(FIND "${template_dir}/" "${work_dir}/" position)
  if(work_dir STREQUAL "/" OR position EQUAL 0)
    selftest_fail("Unsafe WORK_DIR: ${WORK_DIR}")
  endif()
  file(REMOVE_RECURSE "${work_dir}")
  file(MAKE_DIRECTORY "${work_dir}")
endfunction()

# ---------------------------------------------------------------------
# Start of the case
# ---------------------------------------------------------------------
selftest_require_absolute_path(TEMPLATE_DIR)
selftest_require_absolute_path(WORK_DIR)
selftest_assert_exists("${TEMPLATE_DIR}/generate.cmake")
selftest_reset_work_dir()
