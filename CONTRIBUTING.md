# Contributing to Lab Conda Recipes

Thank you for contributing to our lab's conda recipe collection! This guide will help you submit new recipes or update existing ones.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Creating a New Recipe](#creating-a-new-recipe)
- [Recipe Standards](#recipe-standards)
- [Testing Your Recipe](#testing-your-recipe)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Review Process](#review-process)
- [Common Patterns](#common-patterns)
- [Troubleshooting](#troubleshooting)

## Getting Started

### Prerequisites

Before contributing, ensure you have:
- Git installed and configured
- A GitHub account with access to this repository
- Basic familiarity with conda/mamba package management
- Understanding of the software you're packaging

### Development Setup

1. **Install rattler-build**:
   ```bash
   # Option 1: Using pixi (recommended)
   pixi global install rattler-build
   
   # Option 2: Using conda/mamba
   conda install -c conda-forge rattler-build
   
   # Option 3: Using cargo
   cargo install rattler-build
   ```

2. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd packages
   ```

3. **Verify installation**:
   ```bash
   rattler-build --version
   ```

## Creating a New Recipe

### Step 1: Plan Your Recipe

Before creating a recipe, answer these questions:
- Is this package already available in conda-forge? (Check at https://anaconda.org/)
- What are the package dependencies?
- Which platforms do we need to support? (linux-64, osx-64, osx-arm64, win-64)
- What build tools are required? (compiler, cmake, cargo, etc.)
- Does it need patches or custom build steps?

### Step 2: Create Recipe Directory

```bash
cd recipes
mkdir your-package-name
cd your-package-name
```

**Naming conventions**:
- Use lowercase names
- Use hyphens (`-`) not underscores (`_`)
- Match the upstream project name when possible
- For Python packages: use the PyPI name
- For R packages: use `r-<package-name>`

### Step 3: Create recipe.yaml

Create a `recipe.yaml` file with the following structure:

```yaml
context:
  name: your-package-name
  version: "1.0.0"

package:
  name: ${{ name }}
  version: ${{ version }}

source:
  url: https://github.com/org/repo/archive/v${{ version }}.tar.gz
  sha256: abc123...  # Use `curl -L <url> | sha256sum`

build:
  number: 0
  script:
    - echo "Build commands here"

requirements:
  build:
    - ${{ compiler('c') }}
  host:
    - python
  run:
    - python

tests:
  - script:
    - your-package-name --version

about:
  homepage: https://example.com
  license: MIT
  license_file: LICENSE
  summary: Brief one-line description
  description: |
    Longer description of what this package does
    and why it's useful for our lab.
  repository: https://github.com/org/repo
  documentation: https://docs.example.com
```

### Step 4: Add Build Scripts (if needed)

For complex builds, create separate build scripts:

**build.sh** (Linux/macOS):
```bash
#!/bin/bash
set -ex

# Build commands
make
make install PREFIX=$PREFIX
```

**build.bat** (Windows):
```batch
@echo on

REM Build commands
cmake -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% .
cmake --build . --target install
```

Make scripts executable:
```bash
chmod +x build.sh
```

### Step 5: Add Patches (if needed)

If you need to patch the source:

```bash
mkdir patches
# Add your .patch files here
```

Reference in recipe.yaml:
```yaml
source:
  url: https://...
  sha256: ...
  patches:
    - patches/001-fix-compilation.patch
```

## Recipe Standards

### Required Fields

Every recipe MUST have:
- `package.name` - Package name
- `package.version` - Version number
- `source` - Source URL or git repository
- `build` - Build instructions
- `about.license` - License identifier (SPDX format preferred)
- `about.summary` - Brief description

### Recommended Fields

- `about.homepage` - Project homepage
- `about.repository` - Source code repository
- `about.documentation` - Documentation URL
- `tests` - At least basic import/version tests
- `source.sha256` - Checksum for source archives

### Version Pinning

Use appropriate version constraints:

```yaml
requirements:
  run:
    - python >=3.8,<4
    - numpy >=1.20
    - requests >=2.25,<3
```

**Guidelines**:
- Pin major versions for libraries with breaking changes
- Use lower bounds for runtime dependencies
- Avoid overly restrictive pins unless necessary
- Follow upstream's dependency specifications

### Platform Selectors

Use selectors for platform-specific requirements:

```yaml
requirements:
  build:
    - ${{ compiler('c') }}
    - make  # [unix]
    - cmake  # [win]
  run:
    - glibc  # [linux]
```

Available selectors:
- `[unix]` - Linux and macOS
- `[linux]` - Linux only
- `[osx]` - macOS only
- `[win]` - Windows only
- `[arm64]` - ARM64 architecture
- `[x86_64]` - x86_64 architecture

## Testing Your Recipe

### Local Build Test

```bash
cd recipes/your-package-name
rattler-build build --recipe recipe.yaml
```

This will:
1. Download the source
2. Apply any patches
3. Run the build script
4. Create the package in `./output/`

### Test Installation

```bash
# Create a test environment
pixi init test-env
cd test-env

# Add local channel
pixi project channel add file://../../output

# Install your package
pixi add your-package-name

# Test it works
pixi run your-package-name --version
```

### Run Package Tests

If your recipe includes tests, they will run automatically during build. To run them manually:

```bash
rattler-build test --package-file output/your-package-*.conda
```

### Test on Multiple Platforms

For multi-platform packages:
- Test on Linux first (easiest)
- Use GitHub Actions to test on all platforms (happens automatically in CI)
- For local testing on macOS/Windows, use the same `rattler-build build` command

## Submitting a Pull Request

### 1. Create a Branch

```bash
git checkout -b add-your-package-name
```

Branch naming:
- `add-<package>` - For new recipes
- `update-<package>` - For version updates
- `fix-<package>` - For bug fixes

### 2. Commit Your Changes

```bash
git add recipes/your-package-name/
git commit -m "Add recipe for your-package-name v1.0.0"
```

**Commit message guidelines**:
- Use imperative mood ("Add recipe" not "Added recipe")
- Include package version in the message
- For updates, mention what changed

Examples:
```
Add recipe for scanpy v1.9.3
Update numpy to v1.24.0
Fix build script for bedtools on macOS
Add patches for samtools compilation on arm64
```

### 3. Push and Open PR

```bash
git push origin add-your-package-name
```

Then open a Pull Request on GitHub with:

**Title**: `Add <package-name> v<version>`

**Description template**:
```markdown
## Package Information

- **Name**: your-package-name
- **Version**: 1.0.0
- **Homepage**: https://...
- **License**: MIT

## Description

Brief description of what this package does and why we need it in our lab.

## Testing

- [ ] Recipe builds successfully locally
- [ ] Package installs correctly
- [ ] Basic functionality tested
- [ ] Tests pass

## Checklist

- [ ] Recipe follows naming conventions
- [ ] All required fields present
- [ ] Dependencies properly specified
- [ ] Tests included
- [ ] License information correct
- [ ] Works on required platforms

## Additional Notes

Any special considerations, known issues, or platform-specific notes.
```

## Review Process

### What Happens After You Submit

1. **Automated Checks** (5-10 minutes):
   - Recipe format validation
   - Linting checks
   - Test build on Linux

2. **Manual Review** (1-3 days):
   - A maintainer reviews your recipe
   - May request changes or ask questions

3. **Approval and Merge**:
   - Once approved, your PR will be merged
   - CI/CD automatically builds and publishes to prefix.dev

### Review Criteria

Reviewers check for:
- ✅ Recipe builds successfully
- ✅ Tests are meaningful and pass
- ✅ Dependencies are correctly specified
- ✅ License information is accurate
- ✅ Package is useful for lab workflows
- ✅ Follows repository conventions
- ✅ Documentation is clear

### Responding to Review Feedback

```bash
# Make requested changes
git add recipes/your-package-name/
git commit -m "Address review feedback: fix dependency pins"
git push origin add-your-package-name
```

The PR will automatically update and re-run checks.

## Common Patterns

### Python Package (from PyPI)

```yaml
context:
  name: my-python-pkg
  version: "1.0.0"

package:
  name: ${{ name }}
  version: ${{ version }}

source:
  url: https://pypi.io/packages/source/m/my-python-pkg/my-python-pkg-${{ version }}.tar.gz
  sha256: abc123...

build:
  number: 0
  script:
    - python -m pip install . -vv --no-deps --no-build-isolation

requirements:
  host:
    - python >=3.8
    - pip
    - setuptools
  run:
    - python >=3.8
    - numpy >=1.20

tests:
  - python:
      imports:
        - my_python_pkg
  - script:
    - python -c "import my_python_pkg; print(my_python_pkg.__version__)"

about:
  homepage: https://github.com/org/my-python-pkg
  license: MIT
  summary: A Python package
```

### Rust/Cargo Package

```yaml
context:
  name: rust-tool
  version: "0.5.0"

package:
  name: ${{ name }}
  version: ${{ version }}

source:
  url: https://github.com/org/rust-tool/archive/v${{ version }}.tar.gz
  sha256: def456...

build:
  number: 0
  script:
    - cargo install --path . --root $PREFIX

requirements:
  build:
    - ${{ compiler('rust') }}
    - cargo
  run:
    - libgcc  # [linux]

tests:
  - script:
    - rust-tool --version
    - rust-tool --help

about:
  homepage: https://github.com/org/rust-tool
  license: Apache-2.0
  license_file: LICENSE
  summary: A Rust-based tool
```

### C/C++ with CMake

```yaml
context:
  name: cpp-tool
  version: "2.1.0"

package:
  name: ${{ name }}
  version: ${{ version }}

source:
  url: https://github.com/org/cpp-tool/archive/v${{ version }}.tar.gz
  sha256: ghi789...

build:
  number: 0
  script:
    - mkdir build
    - cd build
    - cmake -DCMAKE_INSTALL_PREFIX=$PREFIX ..
    - make -j${CPU_COUNT}
    - make install

requirements:
  build:
    - ${{ compiler('cxx') }}
    - cmake
    - make
  host:
    - zlib
  run:
    - zlib

tests:
  - script:
    - cpp-tool --version
    - test -f $PREFIX/bin/cpp-tool  # [unix]

about:
  homepage: https://github.com/org/cpp-tool
  license: GPL-3.0-or-later
  license_file: LICENSE
  summary: A C++ tool
```

### Bioconductor R Package

```yaml
context:
  name: r-biocpackage
  version: "1.2.0"

package:
  name: ${{ name }}
  version: ${{ version }}

source:
  url: https://bioconductor.org/packages/release/bioc/src/contrib/BiocPackage_${{ version }}.tar.gz
  sha256: jkl012...

build:
  number: 0
  script:
    - $R CMD INSTALL --build .

requirements:
  build:
    - ${{ compiler('c') }}
  host:
    - r-base >=4.0
    - bioconductor-biobase
  run:
    - r-base >=4.0
    - bioconductor-biobase

tests:
  - script:
    - $R -e "library('BiocPackage')"

about:
  homepage: https://bioconductor.org/packages/BiocPackage/
  license: Artistic-2.0
  summary: A Bioconductor package
```

## Troubleshooting

### Build Fails: "Source download failed"

**Problem**: Cannot download source archive.

**Solutions**:
1. Verify the URL is correct and accessible
2. Check if the version exists upstream
3. Try downloading manually to test:
   ```bash
   curl -L "https://..." -o test.tar.gz
   ```

### Build Fails: "SHA256 mismatch"

**Problem**: Downloaded file doesn't match expected checksum.

**Solutions**:
1. Recompute the checksum:
   ```bash
   curl -L "https://..." | sha256sum
   ```
2. Update the `sha256` field in recipe.yaml

### Build Fails: "Command not found"

**Problem**: Build tool is missing.

**Solutions**:
1. Add missing tool to `requirements.build`:
   ```yaml
   requirements:
     build:
       - make
       - cmake
       - ${{ compiler('c') }}
   ```

### Build Fails: "Library not found"

**Problem**: Dependency library is missing.

**Solutions**:
1. Add the library to `requirements.host`:
   ```yaml
   requirements:
     host:
       - zlib
       - openssl
   ```

### Package Installs But Doesn't Work

**Problem**: Runtime dependencies missing.

**Solutions**:
1. Add missing runtime dependencies to `requirements.run`
2. Test in a clean environment:
   ```bash
   pixi init clean-test
   cd clean-test
   pixi add your-package
   pixi run your-package --version
   ```

### Cross-Platform Issues

**Problem**: Builds on Linux but not macOS/Windows.

**Solutions**:
1. Use platform selectors:
   ```yaml
   requirements:
     build:
       - make  # [unix]
       - cmake  # [win]
   ```
2. Check for hardcoded paths (use `$PREFIX` instead of `/usr/local`)
3. Review CI logs for platform-specific errors

### Tests Fail

**Problem**: Package builds but tests fail.

**Solutions**:
1. Test locally first to reproduce
2. Check if tests need additional dependencies
3. Verify test commands are correct
4. Add test data or fixtures if needed

## Getting Help

- **Documentation**: Check the [rattler-build docs](https://prefix-dev.github.io/rattler-build/)
- **Examples**: Browse existing recipes in `recipes/`
- **Ask the team**: Open a discussion issue or ask in lab chat
- **conda-forge**: Look at similar packages on [conda-forge](https://github.com/conda-forge)

## Additional Resources

- [rattler-build Recipe Reference](https://prefix-dev.github.io/rattler-build/latest/reference/recipe_file/)
- [prefix.dev Documentation](https://prefix.dev/docs)
- [conda-forge Contributing Guide](https://conda-forge.org/docs/maintainer/adding_pkgs.html)
- [SPDX License List](https://spdx.org/licenses/)

---

**Questions or Issues?**

If you encounter problems not covered here, please open an issue or reach out to the maintainers.