# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ProjectWizard** is a CMake-based template generator that bootstraps C++ header-only library projects. It is not a library itself — it produces new projects with a complete CMake build system, Catch2 testing, code formatting, and git initialization.

## Generating a New Project

```bash
cd /path/to/desired-project-name
cmake -P /path/to/project_template/generate.cmake
```

The project name is derived from the output directory name. Generation processes all `.in` template files (substituting `@NAME@` and other CMake variables), initializes a git repo, and adds the `cmake_utilities_bootstrap` submodule.

## Building and Testing the Template's Own Presets

This repository has its own `CMakePresets.json` for configuring generated projects. To test a generated project:

```bash
# Configure
cmake --preset default

# Build
cmake --build --preset default

# Run tests
ctest --preset default
```

**Available presets:**
- `default` — Unix Makefiles, strict warnings (`-Wall -Wextra -pedantic -Werror`)
- `multi` — Ninja Multi-Config variant
- `sanitary` — Address and undefined behavior sanitizers enabled

## Architecture

### Generated Project Structure

```
{NAME}/
├── CMakeLists.txt
├── src/
│   ├── CMakeLists.txt
│   ├── include/
│   │   ├── CMakeLists.txt
│   │   └── {NAME}/
│   │       ├── CMakeLists.txt
│   │       └── config.hpp.in
│   ├── lib/
│   │   └── CMakeLists.txt              (empty placeholder)
│   └── bin/
│       └── CMakeLists.txt              (empty placeholder)
├── test/
│   ├── CMakeLists.txt
│   ├── unit/
│   │   └── CMakeLists.txt              (empty placeholder)
│   └── feature/
│       └── CMakeLists.txt              (empty placeholder)
├── cmake/{NAME}_deps.cmake
├── .clang-format
├── .pre-commit-config.yaml
├── .gitignore
├── CMakePresets.json
├── initial-cache.cmake
├── sanitizing-cache.cmake
└── {NAME}-config.cmake.in
```

### Template Files (`.in` suffix)

Each `.in` file maps to a file in the generated project via `configure_file()` in `generate.cmake`:

| Template | Generated File | Purpose |
|----------|---------------|---------|
| `TopLevel.cmake.in` | `CMakeLists.txt` | Root build file |
| `src/CMakeLists.txt.in` | `src/CMakeLists.txt` | Delegates to include, lib, bin |
| `src/include/CMakeLists.txt.in` | `src/include/CMakeLists.txt` | INTERFACE (header-only) library target |
| `src/include/name/CMakeLists.txt.in` | `src/include/{NAME}/CMakeLists.txt` | Configures config.hpp |
| `src/lib/CMakeLists.txt.in` | `src/lib/CMakeLists.txt` | Empty placeholder for compiled libraries |
| `src/bin/CMakeLists.txt.in` | `src/bin/CMakeLists.txt` | Empty placeholder for executables |
| `src/config.hpp.in.in` | `src/include/{NAME}/config.hpp.in` | C++ header with version/compiler info |
| `test/CMakeLists.txt.in` | `test/CMakeLists.txt` | Catch2 test macro and CTest setup |
| `test/unit/CMakeLists.txt.in` | `test/unit/CMakeLists.txt` | Empty placeholder for unit tests |
| `test/feature/CMakeLists.txt.in` | `test/feature/CMakeLists.txt` | Empty placeholder for feature tests |
| `Dependencies.cmake.in` | `cmake/{NAME}_deps.cmake` | Dependency discovery |
| `Config.cmake.in.in` | `{NAME}-config.cmake.in` | CMake package config for consumers |
| `initial-cache.cmake.in` | `initial-cache.cmake` | Default cache variables |
| `sanitizing-cache.cmake.in` | `sanitizing-cache.cmake` | Sanitizer build settings |
| `.pre-commit-config.yaml` | `.pre-commit-config.yaml` | Pre-commit hooks for clang-format |

### Key Design Decisions

- **Header-only libraries**: Generated projects use CMake `INTERFACE` library targets (no compiled `.a`/`.so`)
- **Separated source layout**: `src/include/` for headers, `src/lib/` for compiled libraries, `src/bin/` for executables
- **Separated test layout**: `test/unit/` for unit tests, `test/feature/` for feature/integration tests
- **Catch2 with main**: Tests link against `Catch2::Catch2WithMain` — no custom main needed
- **Test macro**: `@NAME@_add_test(test_name)` creates a test from `${test_name}_test.cpp`, links it, and registers it with CTest
- **Target-based CMake**: Uses modern CMake conventions — namespace targets (`@NAME@::header`), generator expressions, `GNUInstallDirs`
- **Strict by default**: All presets enable `-Wall -Wextra -pedantic -Werror`

### Code Style

`.clang-format` uses a Martin Fowler-inspired style: 80-column limit, 2-space indent, K&R braces, with language-specific overrides for Java, JavaScript, Objective-C, C#, Proto, JSON, Verilog, and TableGen. It is copied into every generated project.
