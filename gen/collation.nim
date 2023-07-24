import std/strutils
import std/algorithm
import std/strscans
import std/bitops

import ./two_stage_table
import ./utils
import ./min_perfect_hash

type CollationElms = seq[uint32]

const
  maxCP = 0x10FFFF
  shiftBit = 6
  continuationBit = 7

proc spaces(input: string; start: int; seps: set[char] = {' '}): int =
  result = 0
  while start+result < input.len and input[start+result] in seps: inc result

type
  CollationItem = object
    cps: seq[int]
    elms: CollationElms

proc parseDucetAll(filePath: string): seq[CollationItem] =
  ## https://unicode.org/reports/tr10/#Allkeys
  result = newSeq[CollationItem]()
  var cps, prop, comment: string
  for line in filePath.lines:
    if line.startsWith("@") or line.startsWith("#"):
      continue
    if scanf(line, "$*;$*#$*", cps, prop, comment):
      result.add CollationItem()
      var cp = 0
      var cpsTmp = ""
      while scanf(cps, "$h$[spaces]$*", cp, cpsTmp):
        cps = cpsTmp
        result[^1].cps.add cp
      doAssert cps == ""
      doAssert result[^1].cps.len > 0
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
        result[^1].elms.add elm
      doAssert prop == ""
      doAssert result[^1].elms.len > 0
  doAssert result.len > 0

proc parseDucet(filePath: string): seq[seq[uint32]] =
  # Single CP key
  result = newSeq[seq[uint32]](maxCP + 1)
  for elm in filePath.parseDucetAll:
    if elm.cps.len == 1:
      let cp = elm.cps[0]
      doAssert result[cp].len == 0
      result[cp] = elm.elms
  # sanity check
  doAssert result[0x07F6] == @[0x05942042'u32]
  doAssert result[0x1FC1] == @[0x04E72042'u32, 0x2A02'u32]

proc parse(filePath: string): seq[CollationElms] =
  result = filePath.parseDucet

type
  CollationDataTable = object
    offsets: seq[int]  # cp -> offset
    elements: CollationElms

proc buildDataSet(data: seq[CollationElms]): CollationDataTable =
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

type
  mkCollationDataSet = object
    mphDataSet: seq[Record[seq[int]]]
    values: CollationElms

proc parseMultiKey(filePath: string): mkCollationDataSet =
  result.mphDataSet = newSeq[Record[seq[int]]]()
  result.values = newSeq[uint32]()
  for elm in filePath.parseDucetAll:
    if elm.cps.len == 1:
      continue
    let offset = result.values.len
    # Using the CPs len instead of a continuation bit here
    # there are only 1K values anyway
    result.mphDataSet.add (key: elm.cps, value: @[elm.cps.len, offset])
    var inelm = 0'u32
    for i, elmX in elm.elms:
      inelm = elmX
      doAssert(not inelm.testBit(continuationBit), "cannot longer use this bit as continuation")
      if i < elm.elms.len-1:
        inelm.setBit continuationBit
      for cp in elm.cps:
        result.values.add cp.uint32
      result.values.add inelm

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

const mkTempl = """## This is auto-generated. Do not modify it

const
  collationMkHashes* = [
    $#
  ]
  collationMkValues* = [
    $#
  ]
  collationMkData* = [
    $#
  ]
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
  
  let mkDataSet = parseMultiKey("./gen/DUCET.txt")
  let mphTables = mph(mkDataSet.mphDataSet)
  var mphValues = newSeq[string](len(mphTables.v))
  for i, v in mphTables.v:
    mphValues[i] = "[$#]" % join(v, "'u16, ")
  f = open("./src/unicodedb/collation_mk_data.nim", fmWrite)
  try:
    f.write(mkTempl % [
      prettyTable(mphTables.h, 15, "'i16"),
      join(mphValues, ",\L    "),
      prettyTable(mkDataSet.values, 15, "'u32", suffixAll = true)])
  finally:
    close(f)
