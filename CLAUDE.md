# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Homebrew tap for OSGeo (Open Source Geospatial) projects on macOS. It provides formulae for geospatial tools like GDAL, PROJ, PostGIS, GRASS, and many others. Formulae are Ruby files that describe how to build and install software packages.

## Working with Formulae

### Formula Structure
- **Location**: All formulae are in `Formula/*.rb`
- **Naming**: Use `osgeo-` prefix for most formulae (e.g., `osgeo-gdal.rb`, `osgeo-postgis.rb`)
- **Aliases**: Located in `Aliases/` directory for shorter names
- **Language**: Ruby DSL specific to Homebrew

### Modern Formula Patterns (2025)

#### Conflict Resolution
**DEPRECATED**: Custom `Unlinked` requirement classes. Use standard `conflicts_with` instead:
```ruby
conflicts_with "gdal", because: "both install the same binaries"
```

#### Modern Bottle Definitions
Use modern bottle syntax with explicit `cellar:` parameter:
```ruby
bottle do
  root_url "https://bottle.download.osgeo.org"
  rebuild 1
  sha256 cellar: :any, ventura: "abc123..."
  sha256 cellar: :any, monterey: "def456..."
  sha256 cellar: :any, sonoma: "ghi789..."
end
```

#### License Declaration
All formulae should include a license:
```ruby
license "MIT"  # or appropriate license
```

#### Python Version
Use specific Python version:
```ruby
depends_on "python@3.12"

def python3
  "python3.12"
end
```

#### Build System Changes
- **PROJ**: Now uses CMake (was autotools in 6.x)
- **GDAL**: Now uses CMake (was autotools in 3.0.x)
- **PostgreSQL**: Still uses autotools but with updated options

## Testing and Building

### Test a Formula Locally
```shell
# Uninstall existing version
brew uninstall --force <formula-name>

# Install from source
brew install --build-from-source <formula-name>

# Run formula tests
brew test <formula-name>

# Audit formula for issues
brew audit --strict <formula-name>
```

### Update a Formula Version
```shell
# Use Homebrew's built-in bump command
brew bump-formula-pr --strict <formula-name> --url=<source-url> --sha256=<checksum>
# OR with git tag
brew bump-formula-pr --strict <formula-name> --tag=<version> --revision=<git-sha>
```

### Edit a Formula
```shell
brew edit <formula-name>
```

## CI/CD System

### GitHub Actions (Primary - 2025)
- **Config**: `.github/workflows/tests.yml`
- **Workflow**: Automated testing on PRs using `brew test-bot`
- **Platforms**: Monterey (12), Ventura (13), Sonoma (14) including ARM64
- **Publish**: `.github/workflows/publish.yml` for bottle publishing

### CircleCI (Legacy)
- **Config**: `.circleci/config.yml`
- **Updated**: Now builds on modern macOS versions (Ventura 14.3.1, Monterey 14.2.0, Sonoma 15.1.0)
- **Changed formulae detection**: `.circleci/changed_formulas.sh` detects which formulae changed
- **Skip list**: `.circleci/skip-formulas.txt` contains formulae to skip in CI
- **Workflow**: Builds changed formulae, creates bottles, and uploads to bottle server

### CI Scripts
- `.circleci/before_install.sh` - Set up build environment (updated for Python 3.12, Apple Silicon)
- `.circleci/install.sh` - Install dependencies
- `.circleci/script.sh` - Build changed formulae
- `.circleci/after_script.sh` - Create bottles

### Travis CI (Deprecated)
- **Config**: `.travis.yml`
- No longer actively maintained

## Utility Scripts

### Update GDAL Versions
```shell
./scripts/update-gdal.sh <version>
```
Updates all GDAL-related formulae with new version and checksums.

## Repository Structure

- `Formula/` - All Homebrew formulae (Ruby files)
- `Aliases/` - Shorter names linking to formulae
- `boneyard/` - Deprecated/removed formulae
- `Requirements/` - Custom Homebrew requirements
- `Strategies/` - Custom download strategies
- `scripts/` - Utility scripts for maintenance
- `docs/` - GitHub Pages documentation site

## Common Tasks

### Adding a New Formula
1. Create formula: `brew create <source-url>`
2. Edit the generated formula in `Formula/`
3. Test: `brew install --build-from-source <formula-name>`
4. Audit: `brew audit --new-formula <formula-name>`
5. Commit with message: `<formula-name> <version> (new formula)`

### Updating Dependencies
When updating a formula, check for:
- Dependent formulae that may need rebuilding
- Version compatibility with PostgreSQL, GDAL, or other core dependencies
- Whether bottles need rebuilding (add/increment `revision` line)

### Handling Bottles
- Bottles are built automatically by CI
- To force bottle rebuild, increment the `revision` number in the formula
- Bottle uploads require appropriate credentials

## Git Workflow

- Use rebase rather than merge (per global instructions)
- Commit message format: `<formula-name> <version>` or `<formula-name>: <description>`
- CI runs only on changed formulae (detected via git diff)

## Important Notes

- **Conflicts with homebrew-core**: Use `conflicts_with` DSL (NOT custom `Unlinked` requirement)
- **PostgreSQL versions**: Now using PostgreSQL 17.x; old @10, @11 versions deprecated
- **Python**: All formulae use `python@3.12` (NOT `python` or `python@2`)
- **Dependencies**: Complex dependency chains exist (e.g., GDAL depends on many libraries)
- **JAVA_HOME**: Some formulae require OpenJDK at build time
- **Bottles**: Pre-compiled binaries stored at `https://bottle.download.osgeo.org`
- **Build options**: The `option` DSL is deprecated; avoid adding new options

## Modernization Status (2025)

### Updated Formulae
- **osgeo-proj** → 9.7.0 (uses CMake, conflicts_with "proj")
- **osgeo-postgresql** → 17.2 (modern service DSL, Python 3.12)
- **osgeo-gdal** → 3.11.5 (uses CMake, Python bindings included)
- **osgeo-postgis** → 3.6.0 (compatible with PostgreSQL 12-17, PROJ 9+)

### Pending Updates
- **osgeo-grass** → 8.4.1 (major version upgrade from 7.x)
- **osgeo-netcdf**, **osgeo-pdal**, and other dependent formulae

### Key Changes
1. CI/CD moved to GitHub Actions with modern macOS versions
2. All bottles use new syntax with explicit `cellar:` parameter
3. Custom `Unlinked` requirements replaced with `conflicts_with`
4. Python 2 references removed throughout
5. Build options deprecated in favor of single configuration
