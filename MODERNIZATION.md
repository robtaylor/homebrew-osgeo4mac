# Homebrew-osgeo4mac Modernization Progress

**Date**: November 7, 2025
**Status**: Phase 1-3 Complete, Phase 4-5 Pending

## Executive Summary

This document tracks the modernization of the homebrew-osgeo4mac tap to work with current Homebrew and macOS versions. The tap contained formulae that were 4-5 years old and used deprecated Homebrew DSL patterns.

## Completed Work

### Phase 1: CI/CD Infrastructure ✅

#### CircleCI Modernization
- **File**: `.circleci/config.yml`
- **Changes**:
  - Replaced High Sierra/Xcode 10.1 builds with modern versions
  - Added Ventura (Xcode 14.3.1), Monterey (Xcode 14.2.0), Sonoma (Xcode 15.1.0) builds
  - Updated cache keys to v2
  - Added support for both Intel (`/usr/local`) and Apple Silicon (`/opt/homebrew`) paths
  - Changed deprecated `brew update-reset` to `brew update`

#### GitHub Actions (New)
- **Files**: `.github/workflows/tests.yml`, `.github/workflows/publish.yml`
- **Features**:
  - Automated testing on PRs using official `brew test-bot`
  - Multi-platform support: macOS 12, 13, 14 (including ARM64)
  - Bottle building and artifact upload
  - Workflow-based bottle publishing

#### CI Scripts Modernization
- **File**: `.circleci/before_install.sh`
- **Changes**:
  - Updated `brew cask install` → `brew install --cask` (modern syntax)
  - Changed `python` → `python@3.12` (specific version)
  - Added Apple Silicon path detection (`/opt/homebrew` vs `/usr/local`)
  - Updated Python 2 → Python 3 throughout
  - Changed `brew unlink python && brew link` to handle python@3.12

### Phase 2: Foundation Packages ✅

#### osgeo-proj 9.7.0
- **Previous**: 6.3.2 (May 2020) - 5.4 years behind
- **Current**: 9.7.0 (September 2025)
- **Major Changes**:
  - Switched from autotools to CMake build system
  - Removed deprecated `Unlinked` requirement class
  - Added standard `conflicts_with "proj"` instead
  - Updated modern bottle syntax with `cellar: :any`
  - Added `license "MIT"` declaration
  - Removed deprecated `skip_clean :la` directive
  - Removed datum grid resources (now included in PROJ data)

#### osgeo-postgresql 17.2
- **Previous**: 12.4 (August 2020) - 5.0 years behind
- **Current**: 17.2 (November 2025)
- **Major Changes**:
  - 5 major version jump (12 → 17)
  - Removed all build options (`with-pg10`, `with-pg11`, `with-cellar`)
  - Removed complex custom `Unlinked` requirement
  - Added standard `conflicts_with "postgresql"`
  - Updated to `python@3.12` from ambiguous `python`
  - Added modern `service do` block (replaces plist_options)
  - Simplified `caveats` with modern upgrade instructions
  - Added `openssl@3`, `lz4`, `zstd` dependencies
  - Added `uses_from_macos` for system libraries
  - Removed obsolete Xcode 9 workarounds

### Phase 3: Core Libraries ✅

#### osgeo-gdal 3.11.5
- **Previous**: 3.1.2 (July 2020) - 5.3 years behind
- **Current**: 3.11.5 (November 2025)
- **Major Changes**:
  - Switched from 383-line autotools formula to 149-line CMake formula
  - Removed all build options and PostgreSQL version selection
  - Removed custom `Unlinked` requirement
  - Added standard `conflicts_with "gdal"`
  - Updated to CMake with modern `-DGDAL_USE_*` flags
  - Integrated Python bindings installation
  - Simplified dependency list (removed osgeo-specific deps where core exists)
  - Changed `depends_on "osgeo-proj"` (still needed for 9.x)
  - Used standard `python@3.12`
  - Removed obsolete patches for Jasper (already fixed upstream)
  - Added comprehensive test including Python bindings and format conversion

#### osgeo-postgis 3.6.0
- **Previous**: 3.0.2 (August 2020) - 5.0 years behind
- **Current**: 3.6.0 (September 2025)
- **Major Changes**:
  - Removed all build options (`with-html-docs`, `with-api-docs`, `with-pg10`, `with-pg11`)
  - Removed custom `Unlinked` requirement
  - Added standard `conflicts_with "postgis"`
  - Simplified dependencies (removed optional doc generation deps)
  - Changed `depends_on "pcre"` → `depends_on "pcre2"`
  - Updated to work with PostgreSQL 12-17 and PROJ 9.x
  - Added Xcode 15 linker workaround for modern toolchain
  - Simplified caveats with clear extension creation instructions

## Pending Work

### Phase 4: Desktop Applications (Pending)

#### osgeo-grass → 8.4.1
- **Current**: 7.8.3 (May 2020)
- **Target**: 8.4.1 (March 2025)
- **Complexity**: Major version jump (7 → 8), many dependencies, ~500+ lines
- **Required Changes**:
  - Remove deprecated build options
  - Update wxPython and GUI dependencies
  - Modernize Python 3.12 integration
  - Update URL (currently uses git branch)
  - Simplify dependency list
  - Remove obsolete patches

### Phase 5: Dependent Formulae (Pending)

Formulae needing updates due to updated dependencies:

- **osgeo-netcdf** → 4.9.x (current: 4.7.4)
- **osgeo-pdal** → 2.8.x (current: 2.1.0)
- **osgeo-hdf4** - May need update for GDAL compatibility
- **osgeo-libspatialite** - Check PROJ 9 compatibility
- **osgeo-libkml** - Check GDAL 3.11 compatibility

## Technical Debt Addressed

### Deprecated Patterns Removed

1. **Custom Unlinked Requirements** → `conflicts_with`
2. **Old Bottle Syntax** → Modern `cellar:` syntax
3. **Build Options** → Single configuration (options deprecated since 2019)
4. **Python 2 References** → Python 3.12
5. **Old macOS Tags** (`:catalina`, `:mojave`) → Modern tags (`ventura:`, `monterey:`, `sonoma:`)
6. **Xcode 9 Workarounds** → Removed (obsolete)
7. **`skip_clean :la`** → Removed (obsolete)

### Modern Patterns Adopted

1. **License Declaration**: All updated formulae include `license` stanza
2. **Service DSL**: PostgreSQL uses modern `service do` block
3. **CMake**: PROJ and GDAL now use CMake instead of autotools
4. **Conflicts**: Standard `conflicts_with` instead of custom requirements
5. **Python Versioning**: Explicit `python@3.12` with helper method
6. **uses_from_macos**: For system libraries like zlib, libxml2
7. **on_macos/on_linux**: Platform-specific dependencies

## Version Comparison

| Formula | Old Version | Old Date | New Version | New Date | Gap |
|---------|-------------|----------|-------------|----------|-----|
| osgeo-proj | 6.3.2 | May 2020 | 9.7.0 | Sep 2025 | 5.4 years |
| osgeo-postgresql | 12.4 | Aug 2020 | 17.2 | Nov 2025 | 5.0 years |
| osgeo-gdal | 3.1.2 | Jul 2020 | 3.11.5 | Nov 2025 | 5.3 years |
| osgeo-postgis | 3.0.2 | Aug 2020 | 3.6.0 | Sep 2025 | 5.0 years |

## Compatibility Matrix

| Formula | PROJ | PostgreSQL | GDAL | Python |
|---------|------|------------|------|--------|
| osgeo-proj | - | - | - | - |
| osgeo-postgresql | - | - | - | 3.12 |
| osgeo-gdal | 9.x | Any | - | 3.12 |
| osgeo-postgis | 9.x | 12-17 | 3.11 | - |
| osgeo-grass | 9.x? | Any? | 3.11? | 3.12? |

## Testing Status

### Audit Status
- ✅ osgeo-proj - Ready for `brew audit --strict`
- ✅ osgeo-postgresql - Ready for audit
- ✅ osgeo-gdal - Ready for audit
- ✅ osgeo-postgis - Ready for audit
- ⏸️ osgeo-grass - Pending update

### Build Status
- ⏸️ All formulae - Require local build testing
- ⏸️ Bottle placeholders need replacement after successful builds
- ⏸️ CI/CD needs testing with updated formulae

### Test Plan

For each updated formula:

1. **Syntax Check**: `brew audit --strict osgeo-<name>`
2. **Build Test**: `brew install --build-from-source osgeo/<tap>/osgeo-<name>`
3. **Functionality Test**: Run formula's `test do` block
4. **Integration Test**: Install dependent formulae
5. **Bottle Build**: Generate bottles on CI

## Known Issues & Caveats

1. **Bottle SHA256s**: All set to "PLACEHOLDER" - need real builds
2. **Dependency Chains**: Must update in order (PROJ → GDAL → PostGIS → GRASS)
3. **Breaking Changes**: Major version jumps may require user data migration
4. **PostgreSQL**: Users with PG 12.x data need `pg_upgrade`
5. **Python Packages**: Existing Python packages may need reinstall

## Migration Guide for Users

### For PostgreSQL Users
```bash
# Back up data
pg_dumpall > backup.sql

# Uninstall old version
brew uninstall osgeo-postgresql

# Install new version
brew install osgeo/osgeo4mac/osgeo-postgresql

# Restore data
psql -f backup.sql
```

### For GDAL Users
```bash
# Uninstall old version and dependencies
brew uninstall --force osgeo-gdal osgeo-proj

# Install new versions
brew install osgeo/osgeo4mac/osgeo-proj
brew install osgeo/osgeo4mac/osgeo-gdal

# Test
gdalinfo --version
```

## Next Steps

1. ✅ Complete CLAUDE.md updates
2. ⏸️ Update osgeo-grass to 8.4.1
3. ⏸️ Update dependent formulae (netcdf, pdal, etc.)
4. ⏸️ Test builds locally
5. ⏸️ Update bottle SHA256s after successful builds
6. ⏸️ Test CI/CD with updated formulae
7. ⏸️ Create PR for community review
8. ⏸️ Deploy bottles to download server
9. ⏸️ Update remaining 80+ formulae using batch scripts

## Estimated Completion

- **Phase 1-3 Complete**: ~4 weeks of work completed ✅
- **Phase 4 (GRASS)**: 1 week estimated
- **Phase 5 (Dependencies)**: 1-2 weeks estimated
- **Testing & Deployment**: 1 week estimated
- **Total Remaining**: 3-4 weeks

## References

- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Homebrew Python Guide](https://docs.brew.sh/Python-for-Formula-Authors)
- [PROJ 9.x Migration](https://proj.org/en/9.0/)
- [GDAL 3.x CMake Build](https://gdal.org/development/building_from_source.html#cmake)
- [PostgreSQL 17 Release Notes](https://www.postgresql.org/docs/17/release-17.html)
