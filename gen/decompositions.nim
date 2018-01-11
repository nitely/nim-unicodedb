import strutils

import unicode_data
import two_stage_table

type
  Decomposition = tuple
    isCanonical: bool
    cps: seq[int]

proc parseDecomps(decompsRaw: seq[string]): seq[Decomposition] =
  result = newSeq[Decomposition](len(decompsRaw))
  for cp, decomp in pairs(decompsRaw):
    if isNil(decomp):
      continue
    result[cp].isCanonical = true
    result[cp].cps = newSeqOfCap[int](18)
    if "<" in decomp:
      result[cp].isCanonical = false
      for d in decomp.split(">")[1].strip().split(" "):
        result[cp].cps.add(parseHexInt("0x$#" % d))
      assert len(result[cp].cps) > 0
      continue
    for d in decomp.split(" "):
      result[cp].cps.add(parseHexInt("0x$#" % d))
    assert len(result[cp].cps) > 0

type
  DecompTable = tuple
    decomps: seq[int]
    offsets: seq[int]

proc buildDecompTable(decomps: seq[Decomposition]): DecompTable =
  var decompsSize = 0
  for dcp in decomps:
    if not isNil(dcp.cps):
      decompsSize += len(dcp.cps) + 1  # + len

  result = (
    decomps: newSeq[int](decompsSize),
    offsets: newSeq[int](len(decomps)))
  for i in 0 ..< len(decomps):
    result.offsets[i] = -1

  var offset = 0
  for cp, dcp in pairs(decomps):
    if isNil(dcp.cps):
      continue
    assert len(dcp.cps) > 0
    # Use length >> 1 to retrieve original length
    # And length & 0x01 to retrieve isCanonical
    # Integer type must be >= int8 for this to work
    var length = len(dcp.cps)
    assert length <= 127
    length = length shl 1
    if dcp.isCanonical:
      length = 0x01 + length

    result.offsets[cp] = offset
    result.decomps[offset] = length
    inc offset
    for dcpcp in dcp.cps:
      result.decomps[offset] = dcpcp
      inc offset

type
  MultiStageTable = tuple
    decomps: seq[int]
    stage1: seq[int]
    stage2: seq[int]
    blockSize: int

proc build(decomps: seq[Decomposition]): MultiStageTable =
  let dcpTable = buildDecompTable(decomps)
  echo dcpTable.offsets[0xFD0A]
  assert dcpTable.offsets[0xFD0A] != -1
  echo dcpTable.decomps[dcpTable.offsets[0xFD0A]]
  assert dcpTable.decomps[dcpTable.offsets[0xFD0A]] == 4
  let stageTable = findBestTable(dcpTable.offsets)
  assert stageTable.blockSize > 0
  echo stageTable.blockSize
  echo len(stageTable.stage1)
  echo len(stageTable.stage2)
  result = (
    decomps: dcpTable.decomps,
    stage1: stageTable.stage1,
    stage2: stageTable.stage2,
    blockSize: stageTable.blockSize)

const decompsTemplate = """## This is auto-generated. Do not modify it

const
  decompsOffsets* = [
    $#
  ]
  decompsIndices* = [
    $#
  ]
  decompsData* = [
    $#
  ]
  blockSize* = $#

"""

when isMainModule:
  let stages = build(
    parseDecomps(parseUDDecomps("./gen/UCD/UnicodeData.txt")))
  var f = open("./src/unicodedb/decompositions_data.nim", fmWrite)
  try:
    f.write(decompsTemplate % [
      join(stages.stage1, "'i8,\n    "),
      join(stages.stage2, "'i16,\n    "),
      join(stages.decomps, "'i32,\n    "),
      intToStr(stages.blockSize)])
  finally:
    close(f)
