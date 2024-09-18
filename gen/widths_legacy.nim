## This module provides legacy data extracted from
## libc's ``wcwidth`` (unicode 5?).
## The ``LC_CTYPE`` of the system
## where this was run is ``en_US.UTF-8``
## (see ``$ locale`` command's output).
## Since this is non-portable,
## this is not part of ``nimble gen``

# TODO: wcwidth returns -1 for everything but ascii on my system (RHEL)
# TODO: remove?

import std/algorithm
import std/strutils

import ./two_stage_table
import ./utils

const maxCP = 0x10FFFF'i32

proc wcwidth(c: cint): cint {.header: "<wchar.h>".}

proc extract(): seq[int] =
  result = newSeq[int](maxCP+1)
  var i = 0
  for cp in 0'i32 .. maxCP:
    if wcwidth(cp) >= 0:
      inc i
    result[cp] = wcwidth(cp)
  echo i

proc build(data: seq[int]): Stages[int] =
  buildTwoStageTable(data)

const dataTemplate = """## This is auto-generated. Do not modify it

const
  widthsIndices* = [
    $#
  ]
  widthsData* = [
    $#
  ]

  blockSize* = $#
"""

when isMainModule:
  let stages = extract().build()

  var f = open("./src/unicodedb/widths_legacy_data.nim", fmWrite)
  try:
    f.write(dataTemplate % [
      prettyTable(stages.stage1, 15, "'i8"),
      prettyTable(stages.stage2, 15, "'i8"),
      $stages.blockSize])
  finally:
    close(f)
