import strutils

import unicode_data
import derived_data
import min_perfect_hash
import utils

proc parseComps(
      decompsRaw: seq[string],
      exclude: seq[int]  # todo: make it a set
    ): seq[Record[seq[int]]] =
  var maxCompSize = 0
  for dcp in decompsRaw:
    if dcp.len > 0:
      inc maxCompSize

  result = newSeqOfCap[Record[seq[int]]](maxCompSize)
  for cp, dcp in pairs(decompsRaw):
    if dcp.len == 0:
      continue
    if cp in exclude:
      continue
    if "<" in dcp:  # Compatibility decomp
      continue
    let dcpParts = dcp.split(" ")
    assert len(dcpParts) == 2
    let
      cp_a = parseHexInt("0x$#" % dcpParts[0])
      cp_b = parseHexInt("0x$#" % dcpParts[1])
    result.add((
      key: @[cp_a, cp_b],
      value: @[cp_a, cp_b, cp]))

const compsTemplate = """## This is auto-generated. Do not modify it

const
  compsHashes* = [
    $#
  ]
  compsValues* = [
    $#
  ]
"""

when isMainModule:
  var decomps = parseComps(
    parseUDDecomps("./gen/UCD/UnicodeData.txt"),
    parseDNPExclusion("./gen/UCD/DerivedNormalizationProps.txt"))
  var mphTables = mph(decomps)
  echo mphLookup(mphTables.h, mphTables.v, [65, 768])

  var compValues = newSeq[string](len(mphTables.v))
  for i, v in mphTables.v:
    assert len(v) == 3
    compValues[i] = "[$#]" % join(v, "'i32, ")

  var f = open("./src/unicodedb/compositions_data.nim", fmWrite)
  try:
    f.write(compsTemplate % [
      prettyTable(mphTables.h, 15, "'i16"),
      join(compValues, ",\L    ")])
  finally:
    close(f)
