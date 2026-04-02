# GitHub Repository Setup Guide

This guide walks you through setting up this repository on GitHub with automated builds and publishing to prefix.dev.

## Table of Contents

- [Initial Repository Setup](#initial-repository-setup)
- [Configuring Secrets](#configuring-secrets)
- [Testing the Workflow](#testing-the-workflow)
- [Troubleshooting](#troubleshooting)

## Initial Repository Setup

### 1. Create GitHub Repository

1. Go to [GitHub](https://github.com) and create a new repository
2. Name it appropriately (e.g., `conda-recipes` or `lab-packages`)
3. Choose visibility:
   - **Public**: Recommended for open-source lab tools
   - **Private**: For internal/proprietary packages
4. Do NOT initialize with README (we already have one)

### 2. Push Existing Code

```bash
cd packages

# Initialize git if not already done
git init

# Add all files
git add .

# Make initial commit
git commit -m "Initial commit: rattler-build recipe repository"

# Add remote (replace with your repository URL)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## Configuring Authentication

### Using Trusted Publishers (Recommended)

prefix.dev supports **Trusted Publishers** via GitHub Actions OIDC, which means no API keys needed!

### Step 1: Configure Trusted Publisher on prefix.dev

1. Go to [prefix.dev](https://prefix.dev) and log in
2. Navigate to your `almost-conductor` channel settings
3. Go to **Trusted Publishers** section
4. Click **Add Trusted Publisher**
5. Configure for GitHub Actions:
   - **Provider**: GitHub
   - **Repository owner**: Your GitHub username/org
   - **Repository name**: Your repository name
   - **Workflow**: `.github/workflows/build.yml`
   - **Environment**: (leave empty for default)
6. Save the configuration

### Step 2: Verify Repository Settings

The GitHub Actions workflow is already configured to use OIDC authentication automatically. No secrets needed!

### Step 3: Verify Configuration
</text>

<old_text line=90>
**Environment Variables:**
- `PREFIX_API_KEY`: Your prefix.dev API token (from secrets)
- `RATTLER_BUILD_VERSION`: Version of rattler-build to use

The repository is now configured! The workflows will:

- ✅ Automatically build recipes when you push to `main`
- ✅ Run validation checks on pull requests
- ✅ Upload successful builds to the `almost-conductor` channel
- ✅ Provide build artifacts for testing

## Understanding the Workflows

### Build Workflow (`.github/workflows/build.yml`)

**Triggers:**
- Push to `main` or `master` branch (with changes in `recipes/`)
- Pull requests (validation only, no publish)
- Manual workflow dispatch

**What it does:**
1. Detects which recipes changed
2. Builds each changed recipe
3. Runs tests
4. On push to `main`: Uploads packages to prefix.dev

**Environment Variables:**
- `PREFIX_API_KEY`: Your prefix.dev API token (from secrets)
- `RATTLER_BUILD_VERSION`: Version of rattler-build to use

### PR Check Workflow (`.github/workflows/pr-check.yml`)

**Triggers:**
- Pull requests that modify recipes

**What it does:**
1. Validates recipe format (YAML syntax, required fields)
2. Lints recipe naming and structure
3. Test builds all changed recipes
4. Posts summary comment on PR

## Testing the Workflow

### Test 1: Verify Trusted Publisher Is Working

Create a simple test workflow run:

1. Go to **Actions** tab in GitHub
2. Select **Build and Publish Recipes**
3. Click **Run workflow**
4. Select the `main` branch
5. Leave recipe blank (builds all changed)
6. Click **Run workflow**

Check the logs to ensure:
- ✅ OIDC authentication works
- ✅ Upload to prefix.dev succeeds
- ✅ No permission errors

### Test 2: Test Recipe Build

Make a small change to trigger a build:

```bash
# Make a trivial change (update build number)
cd recipes/r-anndata
# Edit recipe.yaml and increment build number from 0 to 1

git add recipes/r-anndata/recipe.yaml
git commit -m "Test CI: bump r-anndata build number"
git push
```

Watch the Actions tab to see the build progress.

### Test 3: Test PR Workflow

1. Create a new branch:
   ```bash
   git checkout -b test-pr
   ```

2. Make a change to a recipe

3. Push and open a PR:
   ```bash
   git push -u origin test-pr
   ```

4. Open a Pull Request on GitHub

5. Check that:
   - ✅ PR checks run automatically
   - ✅ Validation passes
   - ✅ Build succeeds
   - ✅ Bot comments with summary

## Troubleshooting

### Issue: "Authentication failed to prefix.dev"

**Cause**: Trusted publisher not configured or incorrect configuration.

**Solution**:
1. Verify trusted publisher is configured on prefix.dev
2. Check that repository owner and name match exactly
3. Ensure workflow path is `.github/workflows/build.yml`
4. Verify you have write access to `almost-conductor` channel

### Issue: "OIDC token request failed"

**Cause**: GitHub Actions OIDC is not properly configured.

**Solution**:
1. Ensure the workflow has `id-token: write` permission (already configured)
2. Check GitHub Actions settings allow OIDC tokens
3. Verify the repository is not using legacy workflows

### Issue: "Permission denied for channel almost-conductor"

**Cause**: GitHub repository not authorized as trusted publisher.

**Solution**:
1. Go to prefix.dev channel settings for `almost-conductor`
2. Check trusted publishers configuration
3. Ensure your GitHub repository is listed
4. Verify repository owner/name match exactly

### Issue: Workflow doesn't trigger on push

**Cause**: Changes not in `recipes/` directory or wrong branch.

**Solution**:
- Ensure changes are in `recipes/` directory
- Push to `main` or `master` branch
- Check `.github/workflows/build.yml` paths configuration

### Issue: Build succeeds but package not on prefix.dev

**Cause**: Upload step may have failed silently or wrong channel.

**Solution**:
1. Check the "Upload to prefix.dev" step logs in Actions
2. Verify you're pushing to the correct channel: `almost-conductor`
3. Check prefix.dev website for the package
4. Allow a few minutes for indexing

## Advanced Configuration

### Custom Build Variants

To build for specific platforms only, edit the recipe:

```yaml
build:
  noarch: generic  # For pure Python/R packages
  # OR
  skip:
    - win  # Skip Windows builds
```

### Multiple Channels

To push to multiple channels, modify `.github/workflows/build.yml`:

```yaml
- name: Upload to prefix.dev
  run: |
    for PACKAGE in $PACKAGES; do
      rattler-build upload prefix -c almost-conductor "$PACKAGE"
      rattler-build upload prefix -c backup-channel "$PACKAGE"
    done
```

### Protected Branches

For better control:

1. Go to **Settings** > **Branches**
2. Add branch protection rule for `main`:
   - ✅ Require pull request reviews
   - ✅ Require status checks (select PR Check workflow)
   - ✅ Require branches to be up to date

## Getting Help

- **Workflow logs**: Check the Actions tab for detailed logs
- **Recipe issues**: Review CONTRIBUTING.md for recipe standards
- **prefix.dev issues**: Check [prefix.dev docs](https://prefix.dev/docs)
- **rattler-build issues**: See [rattler-build docs](https://prefix-dev.github.io/rattler-build/)

## Maintenance

### Managing Trusted Publishers

Trusted publishers provide secure, keyless authentication:

**Benefits:**
- ✅ No secrets to manage or rotate
- ✅ Automatic authentication via OIDC
- ✅ Scoped to specific workflows
- ✅ Auditable and secure

**To update:**
1. Go to prefix.dev channel settings
2. Manage trusted publishers
3. Add/remove repositories as needed

### Monitoring Builds

- Set up email notifications for failed workflows in GitHub settings
- Periodically review Actions tab for build trends
- Keep rattler-build version updated in workflows

---

**Questions?** Open an issue or contact the lab bioinformatics team.