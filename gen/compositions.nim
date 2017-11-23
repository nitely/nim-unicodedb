import strutils

import unicode_data
import derived_n_props
import min_perfect_hash

proc parseComps(
      decompsRaw: seq[string],
      exclude: seq[int]  # todo: make it a set
    ): seq[Record[seq[int]]] =
  var maxCompSize = 0
  for dcp in decompsRaw:
    if not isNil(dcp):
      inc maxCompSize

  result = newSeqOfCap[Record[seq[int]]](maxCompSize)
  for cp, dcp in pairs(decompsRaw):
    if isNil(dcp):
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
    parseUDDecomps("./gen/UnicodeData.txt"),
    parseDNPExclusion("./gen/DerivedNormalizationProps.txt"))
  var mphTables = mph(decomps)
  echo mphLookup(mphTables.h, mphTables.v, [65, 768])

  var compValues = newSeq[string](len(mphTables.v))
  for i, v in mphTables.v:
    assert len(v) == 3
    compValues[i] = "[$#]" % join(v, ", ")

  var f = open("./src/unicodedb/compositions_data.nim", fmWrite)
  try:
    f.write(compsTemplate % [
      join(mphTables.h, "'i16,\n    "),
      join(compValues, ",\n    ")])
  finally:
    close(f)
