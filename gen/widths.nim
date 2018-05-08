## East Asian Width - tr11 (http://www.unicode.org/reports/tr11/)

import algorithm
import strutils

import derived_data
import unicode_data
import two_stage_table
import utils

const maxCP = 0x10FFFF

type
  UnicodeWidth = enum
    uwdtAmbiguous = 0x01  # A
    uwdtFull = 0x02  # F
    uwdtHalf = 0x04  # H
    uwdtNarrow = 0x08  # Na
    uwdtWide = 0x10  # W
    uwdtNeutral = 0x20  # N

proc widthMap(uwdt: string): int =
  case uwdt
  of "A":
    uwdtAmbiguous.ord
  of "F":
    uwdtFull.ord
  of "H":
    uwdtHalf.ord
  of "Na":
    uwdtNarrow.ord
  of "W":
    uwdtWide.ord
  of "N":
    uwdtNeutral.ord
  else:
    raise newException(ValueError, "Bad value: " & uwdt)

proc parseWidth(data: seq[seq[string]]): seq[int] =
  result = newSeq[int](maxCP+1)
  result.fill("N".widthMap())
  for cp, d in data:
    if d.len == 0: continue
    result[cp] = d[0].widthMap()

proc parse(filePath: string): seq[int] =
  filePath.parseUDDNoDups.parseWidth

proc build(data: seq[int]): ThreeStageTable[int] =
  buildThreeStageTable[int](data)

const dataTemplate = """## This is auto-generated. Do not modify it

type
  UnicodeWidth* = enum
    uwdtAmbiguous = $#
    uwdtFull = $#
    uwdtHalf = $#
    uwdtNarrow = $#
    uwdtWide = $#
    uwdtNeutral = $#

const
  widthsOffsets* = [
    $#
  ]
  widthsIndices* = [
    $#
  ]
  widthsData* = [
    $#
  ]

  blockSize* = $#
"""

when isMainModule:
  let stages = build(parse(
    "./gen/UCD/EastAsianWidth.txt"))

  var f = open("./src/unicodedb/widths_data.nim", fmWrite)
  try:
    f.write(dataTemplate % [
      $uwdtAmbiguous.ord,
      $uwdtFull.ord,
      $uwdtHalf.ord,
      $uwdtNarrow.ord,
      $uwdtWide.ord,
      $uwdtNeutral.ord,
      prettyTable(stages.stage1, 15, "'i8"),
      prettyTable(stages.stage2, 15, "'i8"),
      prettyTable(stages.stage3, 15, "'i8"),
      $stages.blockSize])
  finally:
    close(f)
