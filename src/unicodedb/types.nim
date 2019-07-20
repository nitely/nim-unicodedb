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

proc unicodeTypes*(cp: Rune): int {.inline.} =
  ## Return types for a given code point.
  ## Use `contains` to retrieve a single type
  assert cp.int <= 0x10FFFF
  when nimvm:
    #[
    ugly workaround for https://github.com/nitely/nim-regex/issues/4
    typesOffsets.len = 8704
    typesIndices.len = 31104 ; this gives a code size of ~93321 instructions
    (3 instructions per array element), which doesn't fit in `int16.high`
    required in vmgen (0x7fff)
    ]#
    const N = typesIndices.len
    const N2 = N div 3
    const t0 = typesIndices[0 ..< N2]
    const t1 = typesIndices[N2 ..< 2*N2]
    const t2 = typesIndices[2*N2 ..< N]

    proc getTypeIndex(sub: static[int], ind: int): auto =
      when sub == 0: return t0[ind]
      elif sub == 1: return t1[ind]
      else: return t2[ind]
    let blockOffset = (typesOffsets[cp.int div blockSize]).int * blockSize
    block:
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
    block:
      let blockOffset = (typesOffsets[cp.int div blockSize]).int * blockSize
      let idx = typesIndices[blockOffset + cp.int mod blockSize]
      result = typesData[idx]

proc contains*(ut: int, utm: UnicodeTypeMask): bool =
  ## Check if the given type mask is
  ## within the types.
  ##
  ## .. code-block:: nim
  ##   assert utmUppercase in Rune(0x0041).unicodeTypes()
  ##
  result = (ut and utm.int) != 0

proc `+`*(utmA, utmB: UnicodeTypeMask): UnicodeTypeMask =
  (utmA.int or utmB.int).UnicodeTypeMask
