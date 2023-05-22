import std/bitops
import std/unicode

import ./collation_data

type
  CollationElement* = object
    level1*: uint16
    level2*: uint16
    level3*: uint16
    shifted*: bool

# XXX: use https://www.unicode.org/Public/UCD/latest/ucd/Blocks.txt
#      instead of harcoded ranges
proc implicitWeights(cp: Rune): array[2, uint32] =
  ## https://unicode.org/reports/tr10/#Implicit_Weights
  # Tangut
  if cp.int in 0x17000..0x18AFF or cp.int in 0x18D00..0x18D8F:
    result = [
      (0xFB00'u32 shl 16) + (0x0020'u32 shl 8) + 0x0002'u32,
      ((cp.uint32 - 0x17000'u32) or 0x8000'u32) shl 16]
  # Nushu
  elif cp.int in 0x1B170..0x1B2FF:
    result = [
      (0xFB01'u32 shl 16) + (0x0020'u32 shl 8) + 0x0002'u32,
      ((cp.uint32 - 0x1B170'u32) or 0x8000'u32) shl 16]
  # Khitan
  elif cp.int in 0x18B00..0x18CFF:
    result = [
      (0xFB02'u32 shl 16) + (0x0020'u32 shl 8) + 0x0002'u32,
      ((cp.uint32 - 0x18B00'u32) or 0x8000'u32) shl 16]
  # XXX: CJK ranges, Unified_Ideograph=True
  # [((0xFB40 + (cp shr 15)) shl 16) + (0x0020 shl 8) + 0x0002, ((cp and 0x7FFF) or 0x8000) shl 16]
  # XXX: Unified_Ideograph=True
  # [((0xFB80 + (cp shr 15)) shl 16) + (0x0020 shl 8) + 0x0002, ((cp and 0x7FFF) or 0x8000) shl 16]
  else:
    result = [
      ((0xFBC0'u32 + (cp.uint32 shr 15)) shl 16) + (0x0020'u32 shl 8) + 0x0002'u32,
      ((cp.uint32 and 0x7FFF'u32) or 0x8000'u32) shl 16]
  doAssert(not result[0].testBit(shiftBit))
  doAssert(not result[1].testBit(shiftBit))
  doAssert(not result[0].testBit(continuationBit))
  result[0].setBit(continuationBit)

iterator collationElements*(cps: openArray[Rune]): CollationElement {.inline, raises: [].} =
  # if cps.len > 1:
  # get from hash map
  # else
  doAssert cps.len == 1
  let cp = cps[0]
  doAssert cp.int <= 0x10FFFF
  let defaultData = cp.implicitWeights()
  let blockOffset = (collationOffsets[cp.int div blockSize]).int * blockSize
  var idx = collationIndices[blockOffset + cp.int mod blockSize].int
  let hasCollationData = idx > 0
  var elm = 0'u32
  while true:
    if hasCollationData:
      elm = collationData[idx]
    else:
      elm = defaultData[idx]
    # keep single yield
    yield CollationElement(
      level1: elm.bitsliced(16 .. 31).uint16,
      level2: elm.bitsliced(8 .. 15).uint16,
      level3: elm.bitsliced(0 .. 5).uint16,
      shifted: elm.testBit(shiftBit))
    if not elm.testBit(continuationBit):
      break
    inc idx

proc collationElements*(cps: openArray[Rune]): seq[CollationElement] =
  for ce in cps.collationElements:
    result.add ce
