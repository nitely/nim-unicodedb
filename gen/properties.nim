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
  ctgLm = 0x01
  ctgLo = 0x02
  ctgLu = 0x04
  ctgLl = 0x08
  ctgLt = 0x10
  ctgMn = 0x20
  ctgMc = 0x40
  ctgMe = 0x80
  ctgNd = 0x100
  ctgNl = 0x200
  ctgNo = 0x400
  ctgZs = 0x800
  ctgZl = 0x1000
  ctgZp = 0x2000
  ctgCc = 0x4000
  ctgCf = 0x8000
  ctgCs = 0x10000
  ctgCo = 0x20000
  ctgCn = 0x40000
  ctgPc = 0x80000
  ctgPd = 0x100000
  ctgPs = 0x200000
  ctgPe = 0x400000
  ctgPi = 0x800000
  ctgPf = 0x1000000
  ctgPo = 0x2000000
  ctgSm = 0x4000000
  ctgSc = 0x8000000
  ctgSk = 0x10000000
  ctgSo = 0x20000000

  bidirectionalNames* = [
    "L", "LRE", "LRO", "R", "AL", "RLE", "RLO",
    "PDF", "EN", "ES", "ET", "AN", "CS", "NSM", "BN", "B", "S", "WS",
    "ON", "LRI", "RLI", "FSI", "PDI"
  ]

proc categoryMap(s: string): int =
  case s
  of "Lm":
    ctgLm
  of "Lo":
    ctgLo
  of "Lu":
    ctgLu
  of "Ll":
    ctgLl
  of "Lt":
    ctgLt
  of "Mn":
    ctgMn
  of "Mc":
    ctgMc
  of "Me":
    ctgMe
  of "Nd":
    ctgNd
  of "Nl":
    ctgNl
  of "No":
    ctgNo
  of "Zs":
    ctgZs
  of "Zl":
    ctgZl
  of "Zp":
    ctgZp
  of "Cc":
    ctgCc
  of "Cf":
    ctgCf
  of "Cs":
    ctgCs
  of "Co":
    ctgCo
  of "Cn":
    ctgCn
  of "Pc":
    ctgPc
  of "Pd":
    ctgPd
  of "Ps":
    ctgPs
  of "Pe":
    ctgPe
  of "Pi":
    ctgPi
  of "Pf":
    ctgPf
  of "Po":
    ctgPo
  of "Sm":
    ctgSm
  of "Sc":
    ctgSc
  of "Sk":
    ctgSk
  of "So":
    ctgSo
  else:
    assert false
    -1

proc parseProps(propsRaw: seq[seq[string]]): seq[seq[int]] =
  result = newSeq[seq[int]](len(propsRaw))
  for i in 0 ..< len(propsRaw):
    result[i] = @["Cn".categoryMap(), 0]

  for cp, props in pairs(propsRaw):
    if props.len == 0:
      continue
    result[cp][Props.CAT.ord] = props[0].categoryMap()
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
    if qcTVs.len == 0:
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

proc build(props: seq[seq[int]]): ThreeStageTable[seq[int]] =
  buildThreeStageTable(props)

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

type
  UnicodeCategory* = distinct int32
    ## A type for extracting the category
    ## value out of the raw properties.

const
  ctgLm* = $#.UnicodeCategory
  ctgLo* = $#.UnicodeCategory
  ctgLu* = $#.UnicodeCategory
  ctgLl* = $#.UnicodeCategory
  ctgLt* = $#.UnicodeCategory
  ctgMn* = $#.UnicodeCategory
  ctgMc* = $#.UnicodeCategory
  ctgMe* = $#.UnicodeCategory
  ctgNd* = $#.UnicodeCategory
  ctgNl* = $#.UnicodeCategory
  ctgNo* = $#.UnicodeCategory
  ctgZs* = $#.UnicodeCategory
  ctgZl* = $#.UnicodeCategory
  ctgZp* = $#.UnicodeCategory
  ctgCc* = $#.UnicodeCategory
  ctgCf* = $#.UnicodeCategory
  ctgCs* = $#.UnicodeCategory
  ctgCo* = $#.UnicodeCategory
  ctgCn* = $#.UnicodeCategory
  ctgPc* = $#.UnicodeCategory
  ctgPd* = $#.UnicodeCategory
  ctgPs* = $#.UnicodeCategory
  ctgPe* = $#.UnicodeCategory
  ctgPi* = $#.UnicodeCategory
  ctgPf* = $#.UnicodeCategory
  ctgPo* = $#.UnicodeCategory
  ctgSm* = $#.UnicodeCategory
  ctgSc* = $#.UnicodeCategory
  ctgSk* = $#.UnicodeCategory
  ctgSo* = $#.UnicodeCategory

const
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

  echo stages.blockSize
  echo stages.stage1.len
  echo stages.stage2.len
  echo stages.stage3.len

  let propsLen = 4
  let maxCP = 0x10FFFF

  var propsGen = newSeq[string](stages.stage3.len)
  for i, p in stages.stage3:
    assert len(p) == propsLen
    propsGen[i] = "[$#]" % join(p, "'i32, ")
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
      $ctgLm,
      $ctgLo,
      $ctgLu,
      $ctgLl,
      $ctgLt,
      $ctgMn,
      $ctgMc,
      $ctgMe,
      $ctgNd,
      $ctgNl,
      $ctgNo,
      $ctgZs,
      $ctgZl,
      $ctgZp,
      $ctgCc,
      $ctgCf,
      $ctgCs,
      $ctgCo,
      $ctgCn,
      $ctgPc,
      $ctgPd,
      $ctgPs,
      $ctgPe,
      $ctgPi,
      $ctgPf,
      $ctgPo,
      $ctgSm,
      $ctgSc,
      $ctgSk,
      $ctgSo,
      join(bidirectionalNamesGen, ",\n    "),
      prettyTable(stages.stage1, 15, "'i16"),
      prettyTable(stages.stage2, 15, "'u8"),
      join(propsGen, ",\n    "),
      intToStr(stages.blockSize)])
  finally:
    close(f)
