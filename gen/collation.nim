import std/strutils
import std/algorithm
import std/strscans
import std/bitops

import ./utils
import ./min_perfect_hash

type CollationElms = seq[uint32]

const
  maxCP = 0x10FFFF
  shiftBit = 6
  continuationBit = 7
  mphKeyLenBits = 28 .. 31  # 4 MSB

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
        doAssert(not elm.testBit(continuationBit), "cannot longer use this bit as continuation")
        if prop != "":
          elm.setBit continuationBit
        result[^1].elms.add elm
      doAssert prop == ""
      doAssert result[^1].elms.len > 0
  doAssert result.len > 0

type
  MkCollationDataSet = object
    mphDataSet: seq[Record[uint32]]
    values: CollationElms

proc parseMultiKey(filePath: string): MkCollationDataSet =
  result.mphDataSet = newSeq[Record[uint32]]()
  result.values = newSeq[uint32]()
  var sanityCheck = false
  for elm in filePath.parseDucetAll:
    # Use hash map value as CPs len + offset,
    # len is stored in most significant bits
    # Note we could also store collation elements len
    # instead of using a continuation bit (but too late for that)
    let keyLen = elm.cps.len.uint32 shl mphKeyLenBits.a
    doAssert keyLen.bitsliced(mphKeyLenBits) == elm.cps.len.uint32
    doAssert result.values.len.bitsliced(mphKeyLenBits) == 0, "cannot longer use these bits as mphKeyLenBits"
    let offset = result.values.len.uint32 + keyLen
    result.mphDataSet.add (key: elm.cps, value: offset)
    for cp in elm.cps:
      result.values.add cp.uint32
    result.values.add elm.elms
    # sanity check
    if elm.cps == @[0x0E40, 0x0E2D]:
      doAssert elm.elms == @[0x33ac2082'u32, 0x33ba2002'u32]
      sanityCheck = true
  doAssert sanityCheck

proc maxKeyLen(ds: MkCollationDataSet): int =
  result = 0
  for v in ds.mphDataSet:
    result = max(result, v.value.bitsliced(mphKeyLenBits).int)

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

  shiftBit* = $#
  continuationBit* = $#
  mphKeyLenBits* = $#
  collationMaxKeyLen* = $#
"""

when isMainModule:
  let mkDataSet = parseMultiKey("./gen/DUCET.txt")
  let mphTables = mph(mkDataSet.mphDataSet)
  let collationMaxKeyLen = maxKeyLen(mkDataSet)
  let f = open("./src/unicodedb/collation_mk_data.nim", fmWrite)
  try:
    f.write(mkTempl % [
      prettyTable(mphTables.h, 15, "'u32"),
      prettyTable(mphTables.v, 15, "'u32"),
      prettyTable(mkDataSet.values, 15, "'u32", suffixAll = true),
      $shiftBit,
      $continuationBit,
      $mphKeyLenBits,
      $collationMaxKeyLen])
  finally:
    close(f)
