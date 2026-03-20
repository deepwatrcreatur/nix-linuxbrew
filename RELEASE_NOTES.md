# Release Notes

## v1.1.0 - NixOS Module Support (2026-03-19)

### New Features

**NixOS System Module**: Added `nixosModules.default` for system-level directory setup.

On NixOS, creating `/home/linuxbrew` requires root privileges. The new NixOS module handles this during system activation:

```nix
{ inputs, ... }:
{
  imports = [ inputs.nix-linuxbrew.nixosModules.default ];
  programs.linuxbrew.enableSystemSetup = true;
}
```

### Architecture

The flake now provides two complementary modules:

| Module | Runs As | Purpose |
|--------|---------|---------|
| `nixosModules.default` | root | Creates `/home/linuxbrew` with proper ownership |
| `homeManagerModules.default` | user | Installs Homebrew, manages packages, shell integration |

### Upgrade Path

If you were manually creating `/home/linuxbrew` via activation scripts, you can now:

1. Import `nixosModules.default` in your NixOS configuration
2. Set `programs.linuxbrew.enableSystemSetup = true`
3. Remove your manual activation script

### Full Changelog

- Add `nixosModules.default` / `nixosModules.linuxbrew` for NixOS system-level setup
- Add `nixosModule` convenience alias
- Update README with comprehensive documentation for both modules
- Update flake description

---

## v1.0.2 - Bulletproof Linux Homebrew (2026-03-11)

### 🎯 **The Compiler Problem - Solved**

This release addresses the fundamental challenge of running Homebrew on Linux: **building formulae from source requires compilers**, but unlike macOS (which provides Xcode Command Line Tools), Linux Homebrew must provide its own.

### What Was Broken

When users tried to install formulae without pre-built bottles, they encountered:

```
Error: The following formula cannot be installed from bottle and must be
built from source.
  zmx
Install Clang or run `brew install gcc`.
```

Even after `brew install gcc`, builds still failed because:
- GCC installs as **versioned binaries** (`gcc-15`, `g++-15`)
- Formulae expect **unversioned binaries** (`gcc`, `g++`)
- Users had to manually create symlinks - a frustrating experience

### The Root Cause

**Homebrew on macOS vs Linux:**

| Aspect | macOS | Linux |
|--------|-------|-------|
| System Compiler | ✅ Apple Clang (via Xcode CLT) | ❌ None provided |
| Compiler Names | Unversioned (`clang`, `cc`) | Versioned (`gcc-15`) |
| User Setup | Install Xcode CLT once | Install compiler + create symlinks |
| Experience | Seamless | Broken by default |

**Why the difference?** Homebrew on Linux intentionally isolates itself from system libraries (to avoid glibc/ABI conflicts), so it must provide its own toolchain. But GCC's packaging creates versioned binaries to allow multiple versions to coexist.

### The Solution: Auto-Install LLVM

We discovered that **LLVM is superior to GCC for Linux Homebrew** because:

✅ LLVM creates **unversioned symlinks** (`clang`, `clang++`) automatically  
✅ Matches macOS behavior (which uses Clang)  
✅ No manual symlink creation needed  
✅ Works out of the box  

**New in v1.0.2:**

```nix
programs.linuxbrew = {
  enable = true;
  ensureCompiler = true;  # NEW: Default true, auto-installs LLVM
  brews = [ "zmx" ];       # Now builds from source without errors!
};
```

On first `home-manager switch`, the module:
1. Installs Homebrew (if needed)
2. **Installs LLVM automatically** (if `ensureCompiler = true`)
3. Installs your declared formulae

### Why This Design?

**Matches the macOS Homebrew experience:**
- macOS users: Install Xcode CLT → Homebrew works
- Linux users: Install LLVM (automatic) → Homebrew works

**Zero manual intervention required.** Just enable the module, and formulae build from source seamlessly.

### What About GCC?

If you prefer GCC over LLVM, you can:

```nix
programs.linuxbrew = {
  enable = true;
  ensureCompiler = false;  # Disable auto LLVM install
  brews = [ "gcc" ];       # Manually manage compiler
};
```

Then create symlinks manually:
```bash
ln -s ~/.linuxbrew/bin/gcc-15 ~/.linuxbrew/bin/gcc
ln -s ~/.linuxbrew/bin/g++-15 ~/.linuxbrew/bin/g++
```

### Additional Improvements

**brew-wrapper (v1.0.1):**
- Auto-detects available compilers (clang → gcc → gcc-15)
- Sets `HOMEBREW_CC` and `HOMEBREW_CXX` environment variables
- Fallback mechanism if LLVM not yet installed

This provides defense-in-depth: even if LLVM installation fails, the wrapper tries to find any available compiler.

### Other Potential Issues?

We investigated other common Linux Homebrew gotchas:

**✅ Build dependencies:** LLVM automatically pulls in essential tools (binutils, make, etc.)  
**✅ Library conflicts:** Homebrew isolates itself in `/home/linuxbrew/.linuxbrew`  
**✅ Missing tools:** Homebrew auto-installs formula dependencies  
**✅ Bottles:** 99% of formulae have pre-built bottles anyway  

**The compiler was THE issue** - everything else "just works."

### Upgrade Path

**From v1.0.0/v1.0.1:**
1. Update your flake input: `nix flake update nix-linuxbrew`
2. Rebuild: `home-manager switch`
3. LLVM will install automatically on next activation
4. Remove any manual gcc symlinks (no longer needed)

**Fresh install:**
Just works! Enable the module and formulae build from source seamlessly.

### Testing

This release has been validated with:
- ✅ Installing formulae without bottles (`zmx`, custom taps)
- ✅ Building from source with LLVM
- ✅ Fallback to GCC when LLVM unavailable
- ✅ Clean installations (no pre-existing Homebrew)
- ✅ Upgrades from v1.0.0

### Conclusion

**nix-linuxbrew v1.0.2 achieves feature parity with macOS Homebrew.** The compiler setup is now:
- **Automatic** (no manual steps)
- **Transparent** (happens during normal activation)
- **Robust** (works with LLVM or GCC)
- **Optional** (can be disabled if you want manual control)

Linux users can now enjoy the same seamless Homebrew experience as macOS users. 🎉

---

**Full Changelog:**
- Add `ensureCompiler` option (default: true) to auto-install LLVM
- Update activation script to install LLVM before user formulae
- Add compiler detection to brew-wrapper (LLVM → GCC → GCC-15 fallback)
- Document why LLVM is preferred over GCC on Linux
- Add defense-in-depth for compiler availability

**Breaking Changes:** None (new option defaults to sensible behavior)

**Contributors:** @deepwatrcreatur, GitHub Copilot
