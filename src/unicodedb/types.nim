## This module provides common property types:
## Decimal, Digit, Numeric, Lowercase,
## Uppercase and Cased

import unicode

import types_data

export
  UnicodeTypeMask,
  utmDecimal,
  utmDigit,
  utmNumeric,
  utmLowercase,
  utmUppercase,
  utmCased,
  utmWhiteSpace,
  utmWord

proc unicodeTypes*(cp: Rune): int =
  ## Return types for a given code point.
  ## Use `contains` to retrieve a single type
  assert cp.int <= 0x10FFFF
  template impl =
    let blockOffset = (typesOffsets[cp.int div blockSize]).int * blockSize
    let idx = typesIndices[blockOffset + cp.int mod blockSize]
    result = typesData[idx]
  when (NimMajor, NimMinor) >= (1, 1):
    impl()
  else:
    when nimvm:
      # ugly workaround for https://github.com/nitely/nim-regex/issues/4
      const tofN = typesOffsets.len
      const tofN2 = tofN div 2
      const tof0 = typesOffsets[0 ..< tofN2]
      const tof1 = typesOffsets[tofN2 ..< tofN]

      proc getTypeOffset(sub: static[int], ind: int): auto =
        when sub == 0: return tof0[ind]
        else: return tof1[ind]

      const N = typesIndices.len
      const N2 = N div 3
      const t0 = typesIndices[0 ..< N2]
      const t1 = typesIndices[N2 ..< 2*N2]
      const t2 = typesIndices[2*N2 ..< N]

      proc getTypeIndex(sub: static[int], ind: int): auto =
        when sub == 0: return t0[ind]
        elif sub == 1: return t1[ind]
        else: return t2[ind]
      
      let bof = cp.int div blockSize
      let bof2 = bof div tofN2
      let bofI = bof mod tofN2
      var bofIdx = 0'i16
      case bof2
      of 0: bofIdx = getTypeOffset(0, bofI)
      of 1: bofIdx = getTypeOffset(1, bofI)
      of 2: bofIdx = getTypeOffset(2, bofI)
      else: assert false
      let blockOffset = bofIdx.int * blockSize
      let ind = blockOffset + cp.int mod blockSize
      let ind2 = ind div N2
      let j = ind mod N2
      var idx = 0'i8
      case ind2
      of 0: idx = getTypeIndex(0, j)
      of 1: idx = getTypeIndex(1, j)
      of 2: idx = getTypeIndex(2, j)
      else: assert false
      result = typesData[idx]
    else:
      impl()

proc contains*(ut: int, utm: UnicodeTypeMask): bool {.inline.} =
  ## Check if the given type mask is
  ## within the types.
  ##
  ## .. code-block:: nim
  ##   assert utmUppercase in Rune(0x0041).unicodeTypes()
  ##
  result = (ut and utm.int) != 0

proc `+`*(utmA, utmB: UnicodeTypeMask): UnicodeTypeMask {.inline.} =
  (utmA.int or utmB.int).UnicodeTypeMask
