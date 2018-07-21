qxlib - Qliq Cross Platform Library

The purpose of this library is to implement application logic that is shared between all platforms. In theory we could implement everything except GUI. Platform specific projects (ios, android) should use this library by thin wrappers and desktop can call it directly.

Directory structure:
====================
- deps - external projects/libraries that qxlib requires
-- optional - git submodule add https://github.com/akrzemi1/Optional.git
-- rapidjson - git submodule add https://github.com/miloyip/rapidjson.git
-- SQLiteCpp - modified version of https://github.com/SRombauts/SQLiteCpp

- qxlib - source code

Usage
=====
1. Add this project as git submodule:
git submodule add git@git.assembla.com:qxlib.git

2. Init and update all submodules in a recursive way:
git submodule update --init --recursive

Development
===========
git push --recurse-submodules=check