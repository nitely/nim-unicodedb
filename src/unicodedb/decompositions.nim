## This module provides characters
## decomposition used by the normalization form algorithms

import unicode

import decompositions_data

iterator decomposition*(cp: int): int {.inline, raises: [].} =
  ## Iterates over the decomposition of a
  ## given code point, returning each decomposition
  ## code point. Returns at most 18 code points.
  ## This is not a full decomposition.
  assert cp <= 0x10FFFF
  let
    blockOffset = decompsOffsets[cp div blockSize] * blockSize
    idx = decompsIndices[blockOffset + cp mod blockSize]
  if idx != -1:
    let length = decompsData[idx] shr 1
    assert length <= 18
    for i in idx + 1 .. idx + length:
      yield decompsData[i]

iterator decomposition*(cp: Rune): Rune {.inline, raises: [].} =
  ## Iterates over the decomposition of a
  ## given rune, returning each decomposition
  ## rune. Returns at most 18 runes.
  ## This is not a full decomposition.
  for dcp in decomposition(int(cp)):
    yield Rune(dcp)

proc decomposition*[T: int | Rune](cp: T): seq[T] {.raises: [].} =
  ## Return a sequence of the
  ## decomposition for a given code point.
  ## Returns an empty seq when there is no decomposition.
  result = newSeqOfCap[T](18)
  for dcp in decomposition(cp):
    result.add(dcp)

iterator canonicalDecomposition*(cp: int): int {.inline, raises: [].} =
  ## Iterates over the canonical decomposition of a
  ## given code point, returning each decomposition
  ## code point. Returns at most 2 code points.
  ## This is not a full decomposition.
  assert cp <= 0x10FFFF
  let
    blockOffset = decompsOffsets[cp div blockSize] * blockSize
    idx = decompsIndices[blockOffset + cp mod blockSize]
  if idx != -1:
    let
      extra = decompsData[idx]
      isCanonical = (extra and 0x01) == 1
    if isCanonical:
      let length = extra shr 1
      assert length <= 2
      for i in idx + 1 .. idx + length:
        yield decompsData[i]

iterator canonicalDecomposition*(cp: Rune): Rune {.inline, raises: [].} =
  ## Iterates over the canonical decomposition of a
  ## given rune, returning each decomposition
  ## rune. Returns at most 2 runes.
  ## This is not a full decomposition.
  for dcp in canonicalDecomposition(int(cp)):
    yield Rune(dcp)

proc canonicalDecomposition*[T: int | Rune](cp: T): seq[T] {.raises: [].} =
  ## Return a sequence of the canonical
  ## decomposition for a given code point.
  ## It will return an empty sequence when
  ## there is no decomposition.
  result = newSeqOfCap[T](2)
  for dcp in canonicalDecomposition(cp):
    result.add(dcp)

when isMainModule:
  echo(
    (sizeof(decompsOffsets) +
     sizeof(decompsIndices) +
     sizeof(decompsData)) div 1024)
