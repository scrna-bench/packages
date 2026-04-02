# Lab Conda Recipes

This repository contains custom conda package recipes for lab-maintained software and tools needed for our benchmarks, built using [rattler-build](https://github.com/prefix-dev/rattler-build) and published to [prefix.dev](https://prefix.dev).

## Overview

This is a monorepo containing multiple conda recipe feedstocks for packages that are either:
- Not yet available in conda-forge
- Require custom builds or patches for lab-specific use cases
- Experimental or in-development tools

## Repository Structure

```
packages/
├── recipes/
│   ├── package-name-1/
│   │   ├── recipe.yaml
│   │   └── build.sh (optional)
│   ├── package-name-2/
│   │   ├── recipe.yaml
│   │   └── patches/ (optional)
│   └── ...
├── .github/
│   └── workflows/
│       ├── build.yml
│       └── pr-check.yml
└── README.md
```

## Prerequisites

### Installing rattler-build

```bash
# Using pixi (recommended)
pixi global install rattler-build

# Or using conda/mamba
conda install -c conda-forge rattler-build

# Or using cargo
cargo install rattler-build
```

### Setting up prefix.dev authentication

**For CI/CD (GitHub Actions) - Trusted Publishers:**

This repository uses **Trusted Publishers** for secure, keyless authentication to prefix.dev:

1. Go to [prefix.dev](https://prefix.dev) and navigate to the `almost-conductor` channel
2. Go to **Settings** > **Trusted Publishers**
3. Add your GitHub repository as a trusted publisher:
   - Repository owner: your-username-or-org
   - Repository name: your-repo-name
   - Workflow: `.github/workflows/build.yml`
4. Save - No API keys needed!

**For local manual uploads (optional):**

If you need to upload packages manually:

1. Generate an API token from prefix.dev Settings > Access Tokens
2. Set it as an environment variable:
   ```bash
   export PREFIX_API_KEY=your-token-here
   ```

## Creating a New Recipe

### 1. Create recipe directory

```bash
mkdir -p recipes/your-package-name
cd recipes/your-package-name
```

### 2. Create recipe.yaml

The `recipe.yaml` file uses the rattler-build format (similar to conda-build but more modern):

```yaml
context:
  name: your-package-name
  version: "1.0.0"

package:
  name: ${{ name }}
  version: ${{ version }}

source:
  url: https://github.com/org/repo/archive/v${{ version }}.tar.gz
  sha256: <sha256-hash>

build:
  number: 0
  script:
    - cargo build --release  # or appropriate build command
    - mkdir -p $PREFIX/bin
    - cp target/release/binary $PREFIX/bin/

requirements:
  build:
    - ${{ compiler('c') }}
    - ${{ compiler('rust') }}
  host:
    - openssl
  run:
    - openssl

tests:
  - script:
    - your-package-name --version
    - your-package-name --help

about:
  homepage: https://github.com/org/repo
  license: MIT
  license_file: LICENSE
  summary: A brief description of your package
  description: |
    A longer description of what your package does
    and why it's useful.
```

### 3. Build locally

```bash
# From the recipe directory
rattler-build build --recipe recipe.yaml

# Or from repository root
rattler-build build --recipe recipes/your-package-name/recipe.yaml
```

### 4. Test the build

```bash
# Install the built package locally
pixi global install ./output/your-package-name-1.0.0-*.conda

# Or with conda/mamba
conda install -c ./output your-package-name
```

## Contributing Guidelines

### Submitting a new recipe

1. **Fork and clone** this repository
2. **Create a new branch** for your recipe:
   ```bash
   git checkout -b add-package-name
   ```
3. **Add your recipe** in `recipes/package-name/`
4. **Test locally** with `rattler-build build`
5. **Commit and push**:
   ```bash
   git add recipes/package-name/
   git commit -m "Add recipe for package-name v1.0.0"
   git push origin add-package-name
   ```
6. **Open a Pull Request** with:
   - Description of the package
   - Why it's needed for lab work
   - Build test results
   - Any special considerations

### Updating an existing recipe

1. **Update the version** in `recipe.yaml`
2. **Update checksums** if source URL changed
3. **Increment build number** if version stays the same
4. **Test the build** locally
5. **Submit PR** with changelog notes

### Recipe Best Practices

- **Pin dependencies appropriately**: Use version constraints that work but aren't overly restrictive
- **Test thoroughly**: Include meaningful tests in the `tests` section
- **Document patches**: If applying patches, document why in comments
- **Keep it reproducible**: Ensure builds are deterministic
- **Use selectors wisely**: For platform-specific requirements, use selectors like `sel(linux)`

## CI/CD Pipeline

This repository uses GitHub Actions to:
- **Validate** recipes on pull requests
- **Build** packages automatically on merge to main
- **Upload** to prefix.dev channel
- **Test** packages in clean environments

## Publishing to prefix.dev

Packages are automatically published to the `almost-conductor` channel on prefix.dev when merged to the `main` branch.

To use packages from our channel:

```bash
# Add channel to your environment
pixi project channel add https://prefix.dev/almost-conductor

# Or with conda/mamba
conda config --add channels https://prefix.dev/almost-conductor

# Install a package
pixi add -c https://prefix.dev/almost-conductor r-anndata
```

**Manual uploads** (rarely needed, CI handles this automatically):
```bash
# Set your API token
export PREFIX_API_KEY=your-token-here

# Upload package
rattler-build upload prefix -c almost-conductor output/noarch/your-package-*.conda
```

## Troubleshooting

### Common Issues

**Build fails with missing dependencies:**
- Ensure all build/host/run requirements are specified
- Check that dependencies are available in conda-forge or our channel

**SHA256 mismatch:**
- Re-download the source and compute the hash:
  ```bash
  curl -sL <url> | sha256sum
  ```

**Package not found after build:**
- Check the output directory: `./output/`
- Verify the package name and version match expectations

**Upload fails:**
- Verify trusted publisher is configured correctly on prefix.dev
- Check that repository owner/name matches exactly
- Ensure you have write access to the `almost-conductor` channel

## Resources

- [rattler-build documentation](https://prefix-dev.github.io/rattler-build/)
- [prefix.dev documentation](https://prefix.dev/docs)
- [conda-forge recipes](https://github.com/conda-forge) (for examples)
- [Recipe format reference](https://prefix-dev.github.io/rattler-build/latest/reference/recipe_file/)

## Maintainers

This repository is maintained by the lab team. For questions or issues:
- Open an issue in this repository
- Contact the lab bioinformatics team
- Check our internal documentation wiki

## License

Individual recipes may have different licenses. Refer to each recipe's `about.license` field.
This repository structure and tooling is provided as-is for lab use.
