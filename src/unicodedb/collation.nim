import std/bitops
import std/unicode

import ./collation_mk_data
import ./blocks
import ./types

export
  collationMaxKeyLen

when (NimMajor, NimMinor) < (1, 3):
  func bitsliced[T: SomeInteger](v: T; slice: Slice[int]): T =
    let upmost = sizeof(T) * 8 - 1
    (v shl (upmost - slice.b) shr (upmost - slice.b + slice.a)).T

type
  CollationElement* = object
    level1*: uint16
    level2*: uint16
    level3*: uint16
    shifted*: bool

proc fnv32a(key: openarray[Rune], seed: uint32): uint32 =
  result = 18652614'u32  # -> 2166136261 mod int32.high
  if seed > 0'u32:
    result = seed
  for s in key:
    result = result xor uint32(s)
    result = result * 16777619'u32

proc mphLookup(key: openarray[Rune]): array[2, uint32] =
  let d = collationMkHashes[int(fnv32a(key, 0'u32) mod collationMkHashes.len.uint32)]
  result = collationMkValues[int(fnv32a(key, d.uint32) mod collationMkValues.len.uint32)]

proc mkCollationElementsIndex(key: openarray[Rune]): int =
  let mkValue = mphLookup(key)
  let cpLen = mkValue[0].int
  let offset = mkValue[1].int
  if key.len != cpLen:
    return -1
  for i, cp in key.pairs:
    if cp.uint32 != collationMkData[offset+i]:
      return -1
  return cpLen+offset

proc implicitWeights(cp: Rune): array[2, uint32] =
  ## https://unicode.org/reports/tr10/#Implicit_Weights
  if cp in blockTangut:
    result = [
      (0xFB00'u32 shl 16) + (0x0020'u32 shl 8) + 0x0002'u32,
      ((cp.uint32 - 0x17000'u32) or 0x8000'u32) shl 16]
  elif cp in blockNushu:
    result = [
      (0xFB01'u32 shl 16) + (0x0020'u32 shl 8) + 0x0002'u32,
      ((cp.uint32 - 0x1B170'u32) or 0x8000'u32) shl 16]
  elif cp in blockKhitan:
    result = [
      (0xFB02'u32 shl 16) + (0x0020'u32 shl 8) + 0x0002'u32,
      ((cp.uint32 - 0x18B00'u32) or 0x8000'u32) shl 16]
  elif utmUnifiedIdeograph in cp.unicodeTypes() and
      (cp in blockHanUnif or cp in blockHanCompat):
    result = [
      ((0xFB40'u32 + (cp.uint32 shr 15)) shl 16) + (0x0020'u32 shl 8) + 0x0002'u32,
      ((cp.uint32 and 0x7FFF'u32) or 0x8000'u32) shl 16]
  elif utmUnifiedIdeograph in cp.unicodeTypes() and not
      (cp in blockHanUnif or cp in blockHanCompat):
    result = [
      ((0xFB80'u32 + (cp.uint32 shr 15)) shl 16) + (0x0020'u32 shl 8) + 0x0002'u32,
      ((cp.uint32 and 0x7FFF'u32) or 0x8000'u32) shl 16]
  else:
    result = [
      ((0xFBC0'u32 + (cp.uint32 shr 15)) shl 16) + (0x0020'u32 shl 8) + 0x0002'u32,
      ((cp.uint32 and 0x7FFF'u32) or 0x8000'u32) shl 16]
  doAssert(not result[0].testBit(shiftBit))
  doAssert(not result[1].testBit(shiftBit))
  doAssert(not result[0].testBit(continuationBit))
  doAssert(not result[1].testBit(continuationBit))
  result[0].setBit(continuationBit)

iterator collationElements*(cps: openArray[Rune]): CollationElement {.inline, raises: [].} =
  ## Returns nothing if given multiple CPs (multi key) and no mapping is found.
  doAssert cps.len > 0
  for cp in cps:
    doAssert cp.int <= 0x10FFFF
  var idx = mkCollationElementsIndex(cps)
  let isMkCollation = idx != -1
  var defaultData = [0'u32, 0]
  if idx == -1 and cps.len == 1:
    defaultData = cps[0].implicitWeights()
    idx = 0
  var elm = 0'u32
  while true:
    if idx == -1:
      break
    if isMkCollation:
      elm = collationMkData[idx]
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

when isMainModule:
  # nim c -r src/unicodedb/collation.nim
  echo(sizeof(collationMkHashes) div 1024)
  echo(sizeof(collation_mk_data.collationMkData) div 1024)
  const maxCp = 0x10FFFF
  for cp in 0 .. maxCp:
    doAssert collationElements([cp.Rune]).len > 0
    doAssert collationElements([cp.Rune]).len < 20
  doAssert [0x07F6.Rune].collationElements == @[
    CollationElement(
      level1: 0x0594'u16,
      level2: 0x0020'u16,
      level3: 0x0002'u16,
      shifted: true)]
  doAssert [0x1FC1.Rune].collationElements == @[
    CollationElement(
      level1: 0x04E7'u16,
      level2: 0x0020'u16,
      level3: 0x0002'u16,
      shifted: true),
    CollationElement(
      level1: 0x0000'u16,
      level2: 0x002A'u16,
      level3: 0x0002'u16,
      shifted: false)]
  doAssert [0x17000.Rune].collationElements == @[
     CollationElement(
      level1: 64256'u16,
      level2: 32'u16,
      level3: 2'u16,
      shifted: false),
    CollationElement(
      level1: 32768'u16,
      level2: 0'u16,
      level3: 0'u16,
      shifted: false)]
  doAssert [0x0D46.Rune, 0x0D3E.Rune].collationElements == @[
    CollationElement(
      level1: 0x2DA3'u16,
      level2: 0x0020'u16,
      level3: 0x0002'u16,
      shifted: false)]
  doAssert [0x0E40.Rune, 0x0E2D.Rune].collationElements == @[
    CollationElement(
      level1: 0x33AC'u16,
      level2: 0x0020'u16,
      level3: 0x0002'u16,
      shifted: false),
    CollationElement(
      level1: 0x33BA'u16,
      level2: 0x0020'u16,
      level3: 0x0002'u16,
      shifted: false)]
  doAssert [0x07F6.Rune, 0x07F6.Rune].collationElements.len == 0
  doAssert [0x07F6.Rune, 0x07F6.Rune, 0x07F6.Rune].collationElements.len == 0
  doAssert [maxCp.Rune, maxCp.Rune].collationElements.len == 0
  doAssert [0.Rune, 0.Rune].collationElements.len == 0
  doAssert [0.Rune, maxCp.Rune].collationElements.len == 0
  doAssert [maxCp.Rune, 0.Rune].collationElements.len == 0
  # Implicit weight
  doAssert [0x17000.Rune].collationElements == @[
    CollationElement(
      level1: 0xfb00'u16,
      level2: 0x0020'u16,
      level3: 0x0002'u16,
      shifted: false),
    CollationElement(
      level1: 0x8000'u16,
      level2: 0'u16,
      level3: 0'u16,
      shifted: false)]
  doAssert [0x1B170.Rune].collationElements == @[
    CollationElement(
      level1: 0xfb01'u16,
      level2: 0x0020'u16,
      level3: 0x0002'u16,
      shifted: false),
    CollationElement(
      level1: 0x8000'u16,
      level2: 0'u16,
      level3: 0'u16,
      shifted: false)]
  doAssert [0x18B00.Rune].collationElements == @[
    CollationElement(
      level1: 0xfb02'u16,
      level2: 0x0020'u16,
      level3: 0x0002'u16,
      shifted: false),
    CollationElement(
      level1: 0x8000'u16,
      level2: 0'u16,
      level3: 0'u16,
      shifted: false)]
  doAssert [0x4E00.Rune].collationElements == @[
    CollationElement(
      level1: 0xfb40'u16,
      level2: 0x0020'u16,
      level3: 0x0002'u16,
      shifted: false),
    CollationElement(
      level1: 0xce00'u16,
      level2: 0'u16,
      level3: 0'u16,
      shifted: false)]
  doAssert [0xF900.Rune].collationElements == @[
    CollationElement(
      level1: 0xfb41'u16,
      level2: 0x0020'u16,
      level3: 0x0002'u16,
      shifted: false),
    CollationElement(
      level1: 0x8c48'u16,
      level2: 0'u16,
      level3: 0'u16,
      shifted: false)]
  doAssert [0xE000.Rune].collationElements == @[
    CollationElement(
      level1: 0xfbc1'u16,
      level2: 0x0020'u16,
      level3: 0x0002'u16,
      shifted: false),
    CollationElement(
      level1: 0xe000'u16,
      level2: 0'u16,
      level3: 0'u16,
      shifted: false)]
