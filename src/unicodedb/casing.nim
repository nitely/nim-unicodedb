## This module provides casing mappings.
## Beware some mappings are one to many characters

import unicode

import casing_data

template casingImpl(
  offsets, indices, data, blockSize: untyped
): untyped =
  let blockOffset = (offsets[r.int div blockSize]).int * blockSize
  var idx = (indices[blockOffset + r.int mod blockSize]).int
  let idxEnd = if idx > -1: idx+data[idx] else: -1
  var rr = if idx > -1: data[idx+1] else: r.int32
  while true:
    yield rr.Rune
    inc idx
    if idx+1 > idxEnd:
      break
    rr = data[idx+1]

iterator lowerCase*(r: Rune): Rune {.inline.} =
  ## Return lower case mapping of `r` if
  ## there is such mapping. Return `r` otherwise
  assert r.int <= 0x10FFFF
  casingImpl(
    lowercaseOffsets,
    lowercaseIndices,
    lowercaseData,
    lowercaseblockSize)

iterator upperCase*(r: Rune): Rune {.inline.} =
  ## Return upper case mapping of `r` if
  ## there is such mapping. Return `r` otherwise
  assert r.int <= 0x10FFFF
  casingImpl(
    uppercaseOffsets,
    uppercaseIndices,
    uppercaseData,
    uppercaseblockSize)

iterator titleCase*(r: Rune): Rune {.inline.} =
  ## Return title case mapping of `r` if
  ## there is such mapping. Return `r` otherwise
  assert r.int <= 0x10FFFF
  casingImpl(
    titlecaseOffsets,
    titlecaseIndices,
    titlecaseData,
    titlecaseblockSize)
