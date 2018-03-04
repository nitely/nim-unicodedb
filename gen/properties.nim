import strutils
import algorithm

import unicode_data
import derived_data
import two_stage_table
import utils

type
  Props* {.pure.} = enum
    CAT, CCC, BI, QC

const
  categoryNames* = [
    "Cn", "Lu", "Ll", "Lt", "Mn", "Mc", "Me", "Nd",
    "Nl", "No", "Zs", "Zl", "Zp", "Cc", "Cf", "Cs", "Co", "Cn", "Lm",
    "Lo", "Pc", "Pd", "Ps", "Pe", "Pi", "Pf", "Po", "Sm", "Sc", "Sk",
    "So"
  ]
  bidirectionalNames* = [
    "L", "LRE", "LRO", "R", "AL", "RLE", "RLO",
    "PDF", "EN", "ES", "ET", "AN", "CS", "NSM", "BN", "B", "S", "WS",
    "ON", "LRI", "RLI", "FSI", "PDI"
  ]

proc parseProps(propsRaw: seq[seq[string]]): seq[seq[int]] =
  result = newSeq[seq[int]](len(propsRaw))
  for i in 0 ..< len(propsRaw):
    result[i] = @[0, 0]

  for cp, props in pairs(propsRaw):
    if isNil(props):
      continue
    result[cp][Props.CAT.ord] = categoryNames.find(props[0])
    result[cp][Props.CCC.ord] = parseInt(props[1])
    assert result[cp][Props.CAT.ord] >= 0

proc parseBi(biRaw: seq[string]): seq[int] =
  result = newSeq[int](biRaw.len)
  for cp, bi in biRaw:
    result[cp] = bidirectionalNames.find(bi)
    assert result[cp] >= 0

const
  # Default is YES when no NO and no MAYBE
  NfcQcNoMask = 0x01
  NfcQcMaybeMask = 0x02
  NfkcQcNoMask = 0x04
  NfkcQcMaybeMask = 0x08
  NfdQcNoMask = 0x10
  NfkdQcNoMask = 0x20

proc nfMap(qcTV: string): int =
  case qcTV
  of "NFC_QC_N":
    NfcQcNoMask
  of "NFC_QC_M":
    NfcQcMaybeMask
  of "NFKC_QC_N":
    NfkcQcNoMask
  of "NFKC_QC_M":
    NfkcQcMaybeMask
  of "NFD_QC_N":
    NfdQcNoMask
  of "NFKD_QC_N":
    NfkdQcNoMask
  else:
    assert false
    -1

proc parseQC(qcsRaw: seq[seq[string]]): seq[int] =
  result = newSeq[int](qcsRaw.len)
  result.fill(0)
  for cp, qcTVs in qcsRaw:
    if isNil(qcTVs):
      continue
    for qcTV in qcTVs:
      result[cp] = result[cp] or qcTV.nfMap()

proc parse(
      udPath: string,
      dbcPath: string,
      dnpPath: string
    ): seq[seq[int]] =
  echo "unicode data"
  result = udPath.parseUDProps().parseProps()
  echo "derived bidi"
  let bis = dbcPath.parseDBC().parseBi()
  for cp, bi in bis:
    result[cp].add(bi)
  echo "derived qc"
  let qcs = dnpPath.parseDNPQC().parseQC()
  for cp, qc in qcs:
    result[cp].add(qc)

type
  PropsTable = tuple
    props: seq[seq[int]]
    offsets: seq[int]

proc buildPropsTable(props: seq[seq[int]]): PropsTable =
  ## Return table with unique props and offsets
  result = (
    props: newSeqOfCap[seq[int]](255),
    offsets: newSeq[int](len(props)))
  for i in 0 ..< len(props):
    result.offsets[i] = -1
  for cp, p in pairs(props):
    let pIdx = result.props.find(p)
    if pIdx != -1:
      result.offsets[cp] = pIdx
      continue
    result.offsets[cp] = len(result.props)
    result.props.add(p)

type
  MultiStageTable = tuple
    props: seq[seq[int]]
    stage1: seq[int]
    stage2: seq[int]
    blockSize: int

proc build(props: seq[seq[int]]): MultiStageTable =
  let propsTable = buildPropsTable(props)
  echo len(propsTable.props)
  echo len(propsTable.offsets)
  let stageTable = findBestTable(propsTable.offsets)
  assert stageTable.blockSize > 0
  echo stageTable.blockSize
  echo len(stageTable.stage1)
  echo len(stageTable.stage2)
  result = (
    props: propsTable.props,
    stage1: stageTable.stage1,
    stage2: stageTable.stage2,
    blockSize: stageTable.blockSize)

const propsTemplate = """## This is auto-generated. Do not modify it

type
  NfMask* = enum
    ## A type for extracting the QC
    ## (either No or Maybe value)
    ## value out of a raw QC property.
    ## This is used for normalization form algorithms
    nfcQcNo = $#
    nfcQcMaybe = $#
    nfkcQcNo = $#
    nfkcQcMaybe = $#
    nfdQcNo = $#
    nfkdQcNo = $#

const
  categoryNames* = [
    $#
  ]
  bidirectionalNames* = [
    $#
  ]

  propsOffsets* = [
    $#
  ]
  propsIndices* = [
    $#
  ]
  propsData* = [
    $#
  ]

  blockSize* = $#
"""

when isMainModule:
  var stages = build(parse(
    "./gen/UCD/UnicodeData.txt",
    "./gen/UCD/extracted/DerivedBidiClass.txt",
    "./gen/UCD/DerivedNormalizationProps.txt"))

  let propsLen = 4
  let maxCP = 0x10FFFF

  var propsGen = newSeq[string](len(stages.props))
  for i, p in stages.props:
    assert len(p) == propsLen
    propsGen[i] = "[$#]" % join(p, "'i16, ")
  var categoryNamesGen = newSeq[string](len(categoryNames))
  for i, cat in categoryNames:
    categoryNamesGen[i] = "\"$#\"" % cat
  var bidirectionalNamesGen = newSeq[string](len(bidirectionalNames))
  for i, bi in bidirectionalNames:
    bidirectionalNamesGen[i] = "\"$#\"" % bi

  var f = open("./src/unicodedb/properties_data.nim", fmWrite)
  try:
    f.write(propsTemplate % [
      intToStr(NfcQcNoMask),
      intToStr(NfcQcMaybeMask),
      intToStr(NfkcQcNoMask),
      intToStr(NfkcQcMaybeMask),
      intToStr(NfdQcNoMask),
      intToStr(NfkdQcNoMask),
      join(categoryNamesGen, ",\n    "),
      join(bidirectionalNamesGen, ",\n    "),
      prettyTable(stages.stage1, 15, "'u8"),
      prettyTable(stages.stage2, 15, "'u8"),
      join(propsGen, ",\n    "),
      intToStr(stages.blockSize)])
  finally:
    close(f)
