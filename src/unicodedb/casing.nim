## This module provides casing mappings.
## Beware some mappings are one to many characters.

import std/unicode

import ./casing_data

template ones(n: untyped): uint32 = (1.uint32 shl n) - 1

# This jumps through hoops to
# contain a single yield
template casingImpl(
  r, offsets, indices, data, blockSize: untyped
): untyped =
  let blockOffset = (offsets[r.int div blockSize]).int * blockSize
  var idx = (indices[blockOffset + r.int mod blockSize]).int
  # The len is encoded into the 3 least 
  # significant bits of the first cp
  let idxEnd = if idx > -1: idx+(data[idx] and ones(3)).int-1 else: -1
  var rr = if idx > -1: cast[int32](data[idx] shr 3).Rune else: r
  while true:
    yield rr
    inc idx
    if idx > idxEnd:
      break
    rr = cast[int32](data[idx]).Rune

iterator lowerCase*(r: Rune): Rune {.inline.} =
  ## Return lower case mapping of `r` if
  ## there is such mapping. Return `r` otherwise
  doAssert r.int <= 0x10FFFF
  casingImpl(
    r,
    lowercaseOffsets,
    lowercaseIndices,
    lowercaseData,
    lowercaseBlockSize
  )

iterator upperCase*(r: Rune): Rune {.inline.} =
  ## Return upper case mapping of `r` if
  ## there is such mapping. Return `r` otherwise
  doAssert r.int <= 0x10FFFF
  casingImpl(
    r,
    uppercaseOffsets,
    uppercaseIndices,
    uppercaseData,
    uppercaseBlockSize
  )

iterator titleCase*(r: Rune): Rune {.inline.} =
  ## Return title case mapping of `r` if
  ## there is such mapping. Return `r` otherwise
  doAssert r.int <= 0x10FFFF
  casingImpl(
    r,
    titlecaseOffsets,
    titlecaseIndices,
    titlecaseData,
    titlecaseBlockSize
  )

iterator caseFold*(r: Rune): Rune {.inline.} =
  ## Return full case fold of `r` if
  ## there is such folding. Return `r` otherwise.
  ## This is meant for internal usage such as caseless
  ## text comparison
  doAssert r.int <= 0x10FFFF
  casingImpl(
    r,
    casefoldOffsets,
    casefoldIndices,
    casefoldData,
    casefoldBlockSize
  )

func simpleCaseFold*(r: Rune): Rune =
  ## Return simple case fold of `r` if
  ## there is such folding. Return `r` otherwise.
  ## Prefer full case fold which let strings like
  ## "MASSE" and "Maße" to match.
  doAssert r.int <= 0x10FFFF
  let blockOffset = (simpleCasefoldIndices[r.int div simpleCasefoldBlockSize]).int * simpleCasefoldBlockSize
  let cp = simpleCasefoldData[blockOffset + r.int mod simpleCasefoldBlockSize]
  result = if cp == -1: r else: Rune(cp)

func hasCaseFolds*(r: Rune): bool =
  ## Return true if a code point maps to `r` or
  ## `r` maps to a code point. Uses simple case folding.
  doAssert r.int <= 0x10FFFF
  let blockOffset = (hasCasefoldsIndices[r.int div hasCasefoldsBlockSize]).int * hasCasefoldsBlockSize
  result = hasCasefoldsData[blockOffset + r.int mod hasCasefoldsBlockSize] == 1

iterator resolveCaseFold*(r: Rune): Rune {.inline.} =
  ## Return all code points that have the same
  ## simple case-fold map of `r`. It always includes `r`.
  ## Uses simple case folding.
  doAssert r.int <= 0x10FFFF
  casingImpl(
    r.simpleCaseFold(),
    resolveCasefoldOffsets,
    resolveCasefoldIndices,
    resolveCasefoldData,
    resolveCasefoldBlockSize
  )
