## This module provides characters
## decomposition used by the normalization form algorithms

import unicode

import decompositions_data

iterator decompositionImpl(cp: int): int32 {.inline, raises: [].} =
  assert cp <= 0x10FFFF
  let
    blockOffset = int(decompsOffsets[cp div blockSize]) * blockSize
    idx = int(decompsIndices[blockOffset + cp mod blockSize])
  if idx != -1:
    let length = decompsData[idx] shr 1
    assert length <= 18
    for i in idx + 1 .. idx + length:
      yield decompsData[i]

iterator decomposition*(cp: int): int {.inline, raises: [].} =
  ## Iterates over the decomposition of a
  ## given code point, returning each decomposition
  ## code point. Returns at most 18 code points.
  ## This is not a full decomposition.
  for dcp in decompositionImpl(cp):
    yield dcp

iterator decomposition*(cp: Rune): Rune {.inline, raises: [].} =
  ## Iterates over the decomposition of a
  ## given rune, returning each decomposition
  ## rune. Returns at most 18 runes.
  ## This is not a full decomposition.
  for dcp in decompositionImpl(cp.int32):
    yield Rune(dcp)

proc decompositionImpl[T: int | Rune](
    result: var seq[T],
    cp: T) {.raises: [].} =
  result = newSeqOfCap[T](18)
  for dcp in decomposition(cp):
    result.add(dcp)

proc decomposition*(cp: int): seq[int] {.raises: [].} =
  ## Return a sequence of the
  ## decomposition for a given code point.
  ## Returns an empty seq when there is no decomposition.
  decompositionImpl(result, cp)

proc decomposition*(cp: Rune): seq[Rune] {.raises: [].} =
  ## Return a sequence of the
  ## decomposition for a given code point.
  ## Returns an empty seq when there is no decomposition.
  decompositionImpl(result, cp)

iterator canonicalDecompositionImpl(cp: int): int32 {.inline, raises: [].} =
  assert cp <= 0x10FFFF
  let
    blockOffset = int(decompsOffsets[cp div blockSize]) * blockSize
    idx = int(decompsIndices[blockOffset + cp mod blockSize])
  if idx != -1:
    let
      extra = decompsData[idx]
      isCanonical = (extra and 0x01) == 1
    if isCanonical:
      let length = extra shr 1
      assert length <= 2
      for i in idx + 1 .. idx + length:
        yield decompsData[i]

iterator canonicalDecomposition*(cp: int): int {.inline, raises: [].} =
  ## Iterates over the canonical decomposition of a
  ## given code point, returning each decomposition
  ## code point. Returns at most 2 code points.
  ## This is not a full decomposition.
  for dcp in canonicalDecompositionImpl(cp):
    yield dcp

iterator canonicalDecomposition*(cp: Rune): Rune {.inline, raises: [].} =
  ## Iterates over the canonical decomposition of a
  ## given rune, returning each decomposition
  ## rune. Returns at most 2 runes.
  ## This is not a full decomposition.
  for dcp in canonicalDecompositionImpl(cp.int32):
    yield Rune(dcp)

proc canonicalDecompositionImpl[T: int | Rune](
    result: var seq[T],
    cp: T) {.inline, raises: [].} =
  result = newSeqOfCap[T](2)
  for dcp in canonicalDecomposition(cp):
    result.add(dcp)

proc canonicalDecomposition*(cp: int): seq[int] {.raises: [].} =
  ## Return a sequence of the canonical
  ## decomposition for a given code point.
  ## It will return an empty sequence when
  ## there is no decomposition.
  canonicalDecompositionImpl(result, cp)

proc canonicalDecomposition*(cp: Rune): seq[Rune] {.raises: [].} =
  ## Return a sequence of the canonical
  ## decomposition for a given code point.
  ## It will return an empty sequence when
  ## there is no decomposition.
  canonicalDecompositionImpl(result, cp)

when isMainModule:
  echo(
    (sizeof(decompsOffsets) +
     sizeof(decompsIndices) +
     sizeof(decompsData)) div 1024)
