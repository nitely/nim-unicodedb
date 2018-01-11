import strutils
import algorithm

import unicode_data
import derived_data
import two_stage_table

type
  UnicodeTypeMask = enum
    utmDecimal = 0x01
    utmDigit = 0x02
    utmNumeric = 0x04
    utmLowercase = 0x08
    utmUppercase = 0x10
    utmCased = 0x20

proc numTypeMap(numType: string): int =
  case numType
  of "Decimal":
    utmDecimal.ord
  of "Digit":
    utmDigit.ord
  of "Numeric":
    utmNumeric.ord
  else:
    assert false
    -1

proc parseNumericType(numsRaw: seq[seq[string]]): seq[int] =
  result = newSeq[int](numsRaw.len)
  result.fill(0)
  for cp, props in numsRaw:
    if props.isNil:
      continue
    result[cp] = result[cp] or props[0].numTypeMap()

proc parse(dntPath: string): seq[int] =
  echo "derived numType"
  let nums = dntPath.parseUDDNoDups().parseNumericType()
  for cp, nt in nums:
    result[cp] = result[cp] or nt

type
  PropsTable = tuple
    props: seq[int]
    offsets: seq[int]

proc buildPropsTable(props: seq[int]): PropsTable =
  ## Return table with unique props and offsets
  result = (
    props: newSeqOfCap[int](255),
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
    props: seq[int]
    stage1: seq[int]
    stage2: seq[int]
    blockSize: int

proc build(props: seq[int]): MultiStageTable =
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
  UnicodeTypeMask = enum
    utmDecimal = $#
    utmDigit = $#
    utmNumeric = $#
    utmLowercase = $#
    utmUppercase = $#
    utmCased = $#

const
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
    "./gen/UCD/extracted/DerivedNumericType.txt"))

  let propsLen = 4
  let maxCP = 0x10FFFF

  var propsGen = newSeq[string](len(stages.props))
  for i, p in stages.props:
    assert len(p) == propsLen
    propsGen[i] = "[$#]" % join(p, ", ")
  var categoryNamesGen = newSeq[string](len(categoryNames))
  for i, cat in categoryNames:
    categoryNamesGen[i] = "\"$#\"" % cat
  var bidirectionalNamesGen = newSeq[string](len(bidirectionalNames))
  for i, bi in bidirectionalNames:
    bidirectionalNamesGen[i] = "\"$#\"" % bi

  var f = open("./src/unicodedb/types_data.nim", fmWrite)
  try:
    f.write(propsTemplate % [
      $utmDecimal.ord
      $utmDigit.ord
      $utmNumeric.ord
      $utmLowercase.ord
      $utmUppercase.ord
      $utmCased.ord
      join(stages.stage1, "'u8,\n    "),
      join(stages.stage2, "'u8,\n    "),
      join(propsGen, ",\n    "),
      intToStr(stages.blockSize)])
  finally:
    close(f)
