# Build Instructions for Mochi's External Libraries

Mochi is making use of a variety of C APIs such as:
* Sorbet: https://github.com/yampug/sorbet
* Tree-Sitter: https://github.com/yampug/tree-sitter
* Tree-Sitter-Ruby: https://github.com/yampug/tree-sitter-ruby

At this point in time Mochi builds on top of shared libraries, however the current roadmap foresees to switch this out via static linking instead later down the line.

## Building the Libraries
Required tools:
* [Task](https://taskfile.dev) - The task runner itself
* [make](https://www.gnu.org/software/make/) - GNU Make
* [Clang](https://clang.org) or [GCC](https://www.gnu.org/software/gcc/) - C Compiler
* [sed](https://www.gnu.org/software/sed/manual/sed.html) - Stream editor for generting tree-sitter.pc
* [Bazel](https://bazel.build) - Sorbet's chosen build tool

### Building libsorbet

```
gh repo clone yampug/sorbet
cd ./sorbet/lib
task build:linux // or build:macos
// output: ../dist/[linux,macos]/libsorbet.[so,dylib]
```
Copy the `libsorbet.[so,dylib]` into the `./fragements/libs` folder inside the mochi repo.

### Building libtree-sitter

```
gh repo clone yampug/tree-sitter
cd tree-sitter
task build-shared // output: ./libtree-sitter.[so,dylib]
```
Copy the `libtree-sitter.[so,dylib]` into the `./fragements/libs` folder inside the mochi repo.

### Building libtree-sitter-ruby

```
gh repo clone yampug/tree-sitter-ruby
cd tree-sitter-ruby
task shared // output: ./libtree-sitter-ruby.[so,dylib]
```
Copy the `libtree-sitter-ruby.[so,dylib]` into the `./fragements/libs` folder inside the mochi repo.
