## This module provides casing mappings.
## Beware some mappings are one to many characters.

import unicode

import casing_data

# This jumps through hoops to
# contain a single yield
template casingImpl(
  offsets, indices, data, blockSize: untyped
): untyped {.dirty.} =
  let blockOffset = (offsets[r.int div blockSize]).int * blockSize
  var idx = (indices[blockOffset + r.int mod blockSize]).int
  # The len is encoded into the 2 least 
  # significant bits of the first cp
  let idxEnd = if idx > -1: idx+(data[idx] and 0x03).int-1 else: -1
  var rr = if idx > -1: cast[int32](data[idx] shr 2).Rune else: r
  while true:
    yield rr
    inc idx
    if idx > idxEnd:
      break
    rr = cast[int32](data[idx]).Rune

iterator lowerCase*(r: Rune): Rune {.inline.} =
  ## Return lower case mapping of `r` if
  ## there is such mapping. Return `r` otherwise
  assert r.int <= 0x10FFFF
  casingImpl(
    lowercaseOffsets,
    lowercaseIndices,
    lowercaseData,
    lowercaseBlockSize)

iterator upperCase*(r: Rune): Rune {.inline.} =
  ## Return upper case mapping of `r` if
  ## there is such mapping. Return `r` otherwise
  assert r.int <= 0x10FFFF
  casingImpl(
    uppercaseOffsets,
    uppercaseIndices,
    uppercaseData,
    uppercaseBlockSize)

iterator titleCase*(r: Rune): Rune {.inline.} =
  ## Return title case mapping of `r` if
  ## there is such mapping. Return `r` otherwise
  assert r.int <= 0x10FFFF
  casingImpl(
    titlecaseOffsets,
    titlecaseIndices,
    titlecaseData,
    titlecaseBlockSize)

iterator caseFold*(r: Rune): Rune {.inline.} =
  ## Return full case fold of `r` if
  ## there is such folding. Return `r` otherwise.
  ## This is meant for internal usage such as caseless
  ## text comparison
  assert r.int <= 0x10FFFF
  casingImpl(
    casefoldOffsets,
    casefoldIndices,
    casefoldData,
    casefoldBlockSize)
