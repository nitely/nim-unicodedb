import std/strutils
import std/algorithm
import std/strscans
import std/bitops

import ./two_stage_table
import ./utils

const
  maxCP = 0x10FFFF
  shiftBit = 6
  continuationBit = 7

proc spaces(input: string; start: int; seps: set[char] = {' '}): int =
  result = 0
  while start+result < input.len and input[start+result] in seps: inc result

proc parseDucet(filePath: string): seq[seq[uint32]] =
  ## https://unicode.org/reports/tr10/#Allkeys
  # single CP key only
  result = newSeq[seq[uint32]](maxCP + 1)
  var cp: int
  var prop, comment: string
  for line in filePath.lines:
    if scanf(line, "$h$[spaces];$*#$*", cp, prop, comment):
      doAssert result[cp].len == 0
      doAssert prop.strip() != ""
      prop = prop.strip()
      var starOrDot: char
      var coll1, coll2, coll3: int
      var propTmp = ""
      while scanf(prop, "[$c$h.$h.$h]$*", starOrDot, coll1, coll2, coll3, propTmp):
        prop = propTmp
        doAssert starOrDot in "*."
        var elm = 0'u32
        elm += coll1.uint16
        elm = elm shl 8
        elm += coll2.uint8
        elm = elm shl 8
        elm += coll3.uint8
        # 5,6,7 bits are free now; if this changes use a tuple of (u32, u8)
        # or better split into an array[u8]
        doAssert(not elm.testBit(shiftBit), "cannot longer use this bit as shift")
        if starOrDot == '*':
          elm.setBit shiftBit
        result[cp].add elm
      doAssert prop == ""
  # sanity check
  doAssert result[0x07F6] == @[0x05942042'u32]
  doAssert result[0x1FC1] == @[0x04E72042'u32, 0x2A02'u32]

type
  CollationDataTable = ref object
    offsets: seq[int]  # cp -> offset
    elements: seq[uint32]

proc buildDataSet(data: seq[seq[uint32]]): CollationDataTable =
  result = new CollationDataTable
  result.offsets = newSeq[int](maxCP + 1)
  result.elements = @[0'u32]  # reserved for not found
  var elm = 0'u32
  for cp, elms in data:
    if elms.len == 0:
      result.offsets[cp] = 0
      continue
    result.offsets[cp] = result.elements.len
    for i, elmX in elms:
      elm = elmX
      doAssert(not elm.testBit(continuationBit), "cannot longer use this bit as continuation")
      if i < elms.len-1:
        elm.setBit continuationBit
      result.elements.add elm

proc parse(filePath: string): seq[seq[uint32]] =
  result = filePath.parseDucet

const templ = """## This is auto-generated. Do not modify it

const
  collationOffsets* = [
    $#
  ]
  collationIndices* = [
    $#
  ]
  collationData* = [
    $#
  ]

  blockSize* = $#
  shiftBit* = $#
  continuationBit* = $#

"""

when isMainModule:
  let dataSet = parse("./gen/DUCET.txt").buildDataSet()
  let stages = buildTwoStageTable(dataSet.offsets)
  echo stages.blockSize
  echo stages.stage1.len
  echo stages.stage2.len

  var f = open("./src/unicodedb/collation_data.nim", fmWrite)
  try:
    f.write(templ % [
      prettyTable(stages.stage1, 15, "'i16"),
      prettyTable(stages.stage2, 15, "'u16"),
      prettyTable(dataSet.elements, 15, "'u32", suffixAll = true),
      $stages.blockSize,
      $shiftBit,
      $continuationBit])
  finally:
    close(f)
