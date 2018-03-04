import strutils
import algorithm

import unicode_data
import derived_data
import two_stage_table
import utils

type
  UnicodeTypeMask = enum
    utmDecimal = 0x01
    utmDigit = 0x02
    utmNumeric = 0x04
    utmLowercase = 0x08
    utmUppercase = 0x10
    utmCased = 0x20
    utmWhiteSpace = 0x40
    utmWord = 0x80

proc numTypeMap(numType: string): int =
  ## for derived numericType
  case numType
  of "Decimal":
    utmDecimal.ord or utmWord.ord
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

proc coreTypeMap(coreType: string): int =
  ## for derived coreProps
  case coreType
  of "Lowercase":
    utmLowercase.ord
  of "Uppercase":
    utmUppercase.ord
  of "Cased":
    utmCased.ord
  of "Alphabetic":
    utmWord.ord
  else:
    0

proc parseCoreProps(propsRaw: seq[seq[seq[string]]]): seq[int] =
  result = newSeq[int](propsRaw.len)
  result.fill(0)
  for cp, props in propsRaw:
    if props.isNil:
      continue
    for p in props:
      result[cp] = result[cp] or p[0].coreTypeMap()

proc propListTypeMap(propType: string): int =
  ## for propList
  case propType
  of "White_Space":
    utmWhiteSpace.ord
  of "Join_Control":
    utmWord.ord
  else:
    0

proc parsePropList(propsRaw: seq[seq[seq[string]]]): seq[int] =
  result = newSeq[int](propsRaw.len)
  result.fill(0)
  for cp, props in propsRaw:
    if props.isNil:
      continue
    for p in props:
      result[cp] = result[cp] or p[0].propListTypeMap()

proc udCatTypeMap(catType: string): int =
  ## for unicode_data categories
  case catType
  of "Pc":
    utmWord.ord
  of "Mn":
    utmWord.ord
  of "Mc":
    utmWord.ord
  of "Me":
    utmWord.ord
  else:
    0

proc parseUnicodeDataProps(propsRaw: seq[seq[string]]): seq[int] =
  result = newSeq[int](propsRaw.len)
  result.fill(0)
  for cp, props in propsRaw:
    if props.isNil:
      continue
    result[cp] = result[cp] or props[0].udCatTypeMap()

proc parse(
    dntPath: string,
    dctPath: string,
    plPath: string,
    udPath: string): seq[int] =
  echo "derived numType"
  let nums = dntPath.parseUDDNoDups().parseNumericType()
  result = newSeq[int](nums.len)
  result.fill(0)
  for cp, nt in nums:
    result[cp] = result[cp] or nt
  echo "derived coreProps"
  let props = dctPath.parseUDD().parseCoreProps()
  for cp, ct in props:
    result[cp] = result[cp] or ct
  echo "propList"
  let pl = plPath.parseUDD().parsePropList()
  for cp, pp in pl:
    result[cp] = result[cp] or pp
  echo "unicodeData"
  let ud = udPath.parseUDProps().parseUnicodeDataProps()
  for cp, pp in ud:
    result[cp] = result[cp] or pp

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
  UnicodeTypeMask* = enum
    ## For extracting a single type
    ## value out of types
    utmDecimal = $#
    utmDigit = $#
    utmNumeric = $#
    utmLowercase = $#
    utmUppercase = $#
    utmCased = $#
    utmWhiteSpace = $#
    utmWord = $#

const
  typesOffsets* = [
    $#
  ]
  typesIndices* = [
    $#
  ]
  typesData* = [
    $#
  ]

  blockSize* = $#
"""

when isMainModule:
  var stages = build(parse(
    "./gen/UCD/extracted/DerivedNumericType.txt",
    "./gen/UCD/DerivedCoreProperties.txt",
    "./gen/UCD/PropList.txt",
    "./gen/UCD/UnicodeData.txt"))

  var f = open("./src/unicodedb/types_data.nim", fmWrite)
  try:
    f.write(propsTemplate % [
      $utmDecimal.ord,
      $utmDigit.ord,
      $utmNumeric.ord,
      $utmLowercase.ord,
      $utmUppercase.ord,
      $utmCased.ord,
      $utmWhiteSpace.ord,
      $utmWord.ord,
      prettyTable(stages.stage1, 15, "'u8"),
      prettyTable(stages.stage2, 15, "'i8"),
      prettyTable(stages.props, 15, "'i16"),
      $stages.blockSize])
  finally:
    close(f)
