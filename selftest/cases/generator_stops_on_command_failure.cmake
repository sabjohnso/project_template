# Issue 6: the generator must stop when an external command fails.
# This case makes "git commit" fail. Git reads no user configuration.
# Git gets no identity from the environment. The setting
# user.useConfigOnly makes git refuse an identity that it guesses.
include(${CMAKE_CURRENT_LIST_DIR}/../lib/selftest.cmake)

set(empty_home ${WORK_DIR}/home)
set(empty_config ${WORK_DIR}/empty.gitconfig)
file(MAKE_DIRECTORY ${empty_home})
file(WRITE ${empty_config} "")

set(project_dir ${WORK_DIR}/nocommit)
file(MAKE_DIRECTORY ${project_dir})

selftest_run_capture(rv out
  WORKING_DIRECTORY ${project_dir}
  COMMAND ${CMAKE_COMMAND} -E env
    --unset=GIT_AUTHOR_NAME --unset=GIT_AUTHOR_EMAIL
    --unset=GIT_COMMITTER_NAME --unset=GIT_COMMITTER_EMAIL
    --unset=EMAIL
    HOME=${empty_home}
    XDG_CONFIG_HOME=${empty_home}
    GIT_CONFIG_GLOBAL=${empty_config}
    GIT_CONFIG_SYSTEM=${empty_config}
    GIT_CONFIG_COUNT=1
    GIT_CONFIG_KEY_0=user.useConfigOnly
    GIT_CONFIG_VALUE_0=true
    ${CMAKE_COMMAND} -P ${TEMPLATE_DIR}/generate.cmake)

# Confirm that the environment made git commit fail.
selftest_assert_matches("${out}" "user.useConfigOnly|Please tell me who you are|empty ident"
  "git commit must fail in this environment")
selftest_assert_matches("${rv}" "^[1-9]"
  "The generator must fail when git commit fails")
