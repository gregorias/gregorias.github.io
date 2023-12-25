---
layout: post
title:  "Creating a Windows release of Rummikub Solver"
date:   2023-12-25 14:00:00
tags: rummikub-solver ghcup windows msys2
---
This note is about my complete setup to build [Rummikub Solver][rummikubsolver]
on Windows for Windows.

Rummikub Solver is a Haskell application that depends on external C libraries.
As a Unix-native, I found it challenging to figure out a proper way to work
with Windows to create a complete package for Windows users. Luckily, the end
result is not particularly complex.

This setup shows how to utilize [GHCup][ghcup] and [MSYS2][msys2] to have a
working dev environment for compiling Haskell packages.
This setup is definitely not best-practice-compliant, but it works in building
a portable executable package without smelling too much.

## Instructions

Install [GHCup][ghcup]. Bundled with GHCup is also an installation of [[MSYS2]].
It installs Msys in `C:\ghcup\msys64`.  
Open up a unix-like terminal `C:\ghcup\msys64\msys2.exe`.
You'll use the terminal to do the rest of the work.  
Refresh Msys' package manager cache and install dev tools and Rummikub Solver's
dependencies:

```bash
pacman -Sy
pacman -S git zip
# Rummikub Solver depends on GLPK.
# This installs the files into `/mingw64/{bin,include,lib}`
pacman -S mingw-w64-x86_64-glpk
```

Fetch and build Rummikub Solver:

```bash
git clone https://github.com/gregorias/rummikubsolver
cd rummikubsolver
# Normally, we'd add C:\ghcup\bin to PATH.
# Couldn't be bothered to do this for my Windows setup though.
/c/ghcup/bin/stack.exe build
# In the background, either Msys or GHCup have added
# "--extra-include-dirs=/mingw64/include --extra-lib-dirs=/mingw64/lib"
# I have researched how it was it done, but FYI,
# that's how Stack knew where to find GLPK.
```

Create a release package:

```bash
# There's a bunch of DLLs the binary depends,
# that are only in mingw on that the user will need as well.
# You can find them via ldd.exe rummikubsolver.exe.
# We're packaging them into the .zip
#
# One way to avoid this would have been to build with static linking, but
# I couldn't figure out how to do this.
zip -r rummikubsolver-win64.zip \
  resources \
  .stack-work/install/xxx/bin/rummikubsolver.exe \
  /mingw64/libgcc_s_seh-1.dll \
  /mingw64/libglpk-40.dll \
  /mingw64/libgmp-10.dll \
  /mingw64/libwinpthread-1.dll
```

Voila. You can now upload the zip archive for users to download and use.

[ghcup]: https://www.haskell.org/ghcup/
[rummikubsolver]: https://github.com/gregorias/rummikubsolver/
[msys2]: https://www.msys2.org/
