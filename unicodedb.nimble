# Package

version = "0.5.2"
author = "Esteban Castro Borsani (@nitely)"
description = "Unicode Character Database (UCD) access for Nim"
license = "MIT"
srcDir = "src"

skipDirs = @["tests", "gen"]

# Dependencies

requires "nim >= 0.17.2"

task test, "Test":
  exec "nim c -r tests/tests"

task docs, "Docs":
  exec "nim doc2 -o:./docs/unicodedb --project ./src/unicodedb/scripts.nim"
  exec "nim doc2 -o:./docs/unicodedb --project ./src/unicodedb/widths.nim"
  exec "nim doc2 -o:./docs --project ./src/unicodedb.nim"
  exec "mv ./docs/unicodedb.html ./docs/index.html"
  exec "rm -fr ./docs/*/*_data.html"

task gen, "Gen data":
  exec "nim c -r gen/scripts.nim"
  exec "nim c -r gen/widths.nim"
  exec "nim c -r gen/types.nim"
  exec "nim c -r gen/compositions.nim"
  exec "nim c -r gen/decompositions.nim"
  exec "nim c -r gen/names.nim"
  exec "nim c -r gen/properties.nim"

task gen_tests, "Gen test data":
  exec "nim c -r gen/test_data.nim"
