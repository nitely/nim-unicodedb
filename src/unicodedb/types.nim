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
  let
    blockOffset = (typesOffsets[cp.int div blockSize]).int * blockSize
    idx = typesIndices[blockOffset + cp.int mod blockSize]
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
