# Package

version = "0.12.0"
author = "Esteban Castro Borsani (@nitely)"
description = "Unicode Character Database (UCD) access for Nim"
license = "MIT"
srcDir = "src"

skipDirs = @["tests", "gen"]

# Dependencies

requires "nim >= 1.0.0"

task test, "Test":
  exec "nim c -r tests/tests"
  when (NimMajor, NimMinor) >= (2, 0):
    exec "nim c -r --mm:refc tests/tests"

task docs, "Docs":
  exec "nim doc2 -o:./docs/unicodedb --project ./src/unicodedb/segmentation.nim"
  exec "nim doc2 -o:./docs/unicodedb --project ./src/unicodedb/casing.nim"
  exec "nim doc2 -o:./docs/unicodedb --project ./src/unicodedb/scripts.nim"
  exec "nim doc2 -o:./docs/unicodedb --project ./src/unicodedb/widths.nim"
  exec "nim doc2 -o:./docs --project ./src/unicodedb.nim"
  exec "mv ./docs/unicodedb.html ./docs/index.html"
  exec "rm -fr ./docs/*/*_data.html"

task gen, "Gen data":
  exec "nim c -r gen/segmentation.nim"
  exec "nim c -r gen/casing.nim"
  exec "nim c -r gen/scripts.nim"
  exec "nim c -r gen/widths.nim"
  exec "nim c -r gen/types.nim"
  exec "nim c -r gen/compositions.nim"
  exec "nim c -r gen/decompositions.nim"
  exec "nim c -r gen/names.nim"
  exec "nim c -r gen/properties.nim"
  exec "nim c -r -d:release gen/collation.nim"
  exec "nim c -r gen/blocks.nim"

task gen_tests, "Gen test data":
  exec "nim c -r gen/test_data.nim"
