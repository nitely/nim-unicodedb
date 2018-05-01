## This module provides characters
## composition used by the normalization form algorithms

import unicode

import compositions_data

proc fnv32a(
    cpA: Rune,
    cpB: Rune,
    seed: uint32): uint32 {.inline, raises: [].} =
  ## Calculates a distinct hash function for a given sequence
  ## FNV algorithm from http://isthe.com/chongo/tech/comp/fnv/
  result = 18652614'u32  # -> 2166136261 mod int32.high
  if seed > 0'u32:
    result = seed
  result = result xor uint32(cpA)
  result = result * 16777619'u32
  result = result xor uint32(cpB)
  result = result * 16777619'u32

proc mphLookup(cpA: Rune, cpB: Rune): array[3, int32] {.inline, raises: [].} =
  ## Hash map lookup for compositions. Return a
  ## decomposition and its composition
  assert compsHashes.len <= int32.high
  assert compsValues.len <= int32.high
  let d = compsHashes[(fnv32a(cpA, cpB, 0'u32) mod compsHashes.len).int]
  result = compsValues[(fnv32a(cpA, cpB, d.uint32) mod compsValues.len).int]

proc composition*(
    r: var Rune,
    cpA: Rune,
    cpB: Rune): bool {.raises: [].} =
  ## Assign the primary composition for
  ## a given decomposition to ``r`` param.
  ## This is not a full composition.
  ## Return ``true`` if composition
  ## was found, otherwise return ``false``
  assert cpA.int <= 0x10FFFF
  assert cpB.int <= 0x10FFFF
  let cps = mphLookup(cpA, cpB)
  result = cpA == cps[0].Rune and cpB == cps[1].Rune
  r = cps[2].Rune

proc composition*(
    cpA: Rune,
    cpB: Rune): Rune {.raises: [ValueError].} =
  ## Return the primary composition for
  ## a given decomposition. This is not a full composition.
  ## Raises `ValueError` if composition was not found
  if not composition(result, cpA, cpB):
    raise newException(ValueError, "Composition not found")

proc composition*(cpA: int, cpB: int): int {.deprecated.} =
  ## **Deprecated since version 0.3.1**;
  ## Use ``composition(var Rune, Rune, Rune)`` instead.
  var r: Rune
  if not composition(r, cpA.Rune, cpB.Rune):
    result = -1
    return
  result = r.int

when isMainModule:
  echo(
    (sizeof(compsHashes) +
     sizeof(compsValues)) div 1024)
