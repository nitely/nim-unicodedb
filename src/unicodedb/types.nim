## This module provides common property types:
## Decimal, Digit, Numeric, Lowercase,
## Uppercase and Cased

{.push raises: [], gcsafe.}

import std/unicode
when defined(nimPreviewSlimSystem):
  import std/assertions

import ./types_data

export
  UnicodeTypeMask,
  utmDecimal,
  utmDigit,
  utmNumeric,
  utmLowercase,
  utmUppercase,
  utmCased,
  utmWhiteSpace,
  utmWord,
  utmUnifiedIdeograph

proc unicodeTypes*(cp: Rune): int =
  ## Return types for a given code point.
  ## Use `contains` to retrieve a single type
  assert cp.int <= 0x10FFFF
  let blockOffset = (typesOffsets[cp.int div blockSize]).int * blockSize
  let idx = typesIndices[blockOffset + cp.int mod blockSize]
  typesData[idx]

proc contains*(ut: int, utm: UnicodeTypeMask): bool {.inline.} =
  ## Check if the given type mask is
  ## within the types.
  ##
  ## .. code-block:: nim
  ##   assert utmUppercase in Rune(0x0041).unicodeTypes()
  ##
  (ut and utm.int) != 0

proc `+`*(utmA, utmB: UnicodeTypeMask): UnicodeTypeMask {.inline.} =
  (utmA.int or utmB.int).UnicodeTypeMask
