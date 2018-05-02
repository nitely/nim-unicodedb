## This module provides characters
## decomposition used by the normalization form algorithms

import unicode

import decompositions_data

iterator decomposition*(cp: Rune): Rune {.inline, raises: [].} =
  ## Iterates over the decomposition of a
  ## given rune, returning each decomposition
  ## rune. Returns at most 18 runes.
  ## This is not a full decomposition.
  assert cp.int <= 0x10FFFF
  let
    blockOffset = (decompsOffsets[cp.int div blockSize]).int * blockSize
    idx = (decompsIndices[blockOffset + cp.int mod blockSize]).int
  if idx != -1:
    let length = decompsData[idx] shr 1
    assert length <= 18
    for i in idx+1 .. idx+length:
      yield decompsData[i].Rune

iterator decomposition*(cp: int): int {.inline, deprecated.} =
  ## **Deprecated since version 0.3.0**;
  ## Use ``decomposition(Rune)`` instead.
  for dcp in decomposition(cp.Rune):
    yield dcp.int

proc decompositionImpl[T: int | Rune](
    result: var seq[T],
    cp: T) {.raises: [].} =
  result = newSeqOfCap[T](18)
  for dcp in decomposition(cp):
    result.add(dcp)

proc decomposition*(cp: Rune): seq[Rune] {.raises: [].} =
  ## Return a sequence of the
  ## decomposition for a given code point.
  ## Returns an empty seq when there is no decomposition.
  decompositionImpl(result, cp)

proc decomposition*(cp: int): seq[int] {.deprecated.} =
  ## **Deprecated since version 0.3.0**;
  ## Use ``decomposition(Rune)`` instead.
  decompositionImpl(result, cp)

iterator canonicalDecomposition*(cp: Rune): Rune {.inline, raises: [].} =
  ## Iterates over the canonical decomposition of a
  ## given rune, returning each decomposition
  ## rune. Returns at most 2 runes.
  ## This is not a full decomposition.
  assert cp.int <= 0x10FFFF
  let
    blockOffset = (decompsOffsets[cp.int div blockSize]).int * blockSize
    idx = (decompsIndices[blockOffset + cp.int mod blockSize]).int
  if idx != -1:
    let
      extra = decompsData[idx]
      isCanonical = (extra and 0x01) == 1
    if isCanonical:
      let length = extra shr 1
      assert length <= 2
      for i in idx+1 .. idx+length:
        yield decompsData[i].Rune

iterator canonicalDecomposition*(cp: int): int {.inline, deprecated.} =
  ## **Deprecated since version 0.3.0**;
  ## Use ``canonicalDecomposition(Rune)`` instead.
  for dcp in canonicalDecomposition(cp.Rune):
    yield dcp.int

proc canonicalDecompositionImpl[T: int | Rune](
    result: var seq[T],
    cp: T) {.inline, raises: [].} =
  result = newSeqOfCap[T](2)
  for dcp in canonicalDecomposition(cp):
    result.add(dcp)

proc canonicalDecomposition*(cp: Rune): seq[Rune] {.raises: [].} =
  ## Return a sequence of the canonical
  ## decomposition for a given code point.
  ## It will return an empty sequence when
  ## there is no decomposition.
  canonicalDecompositionImpl(result, cp)

proc canonicalDecomposition*(cp: int): seq[int] {.deprecated.} =
  ## **Deprecated since version 0.3.0**;
  ## Use ``canonicalDecomposition(Rune)`` instead.
  canonicalDecompositionImpl(result, cp)

when isMainModule:
  echo(
    (sizeof(decompsOffsets) +
     sizeof(decompsIndices) +
     sizeof(decompsData)) div 1024)
