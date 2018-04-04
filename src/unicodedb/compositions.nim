## This module provides characters
## composition used by the normalization form algorithms

import unicode

import compositions_data

proc fnv32a(key: array[2, int], seed: uint32): uint32 {.inline, raises: [].} =
  ## Calculates a distinct hash function for a given sequence
  ## FNV algorithm from http://isthe.com/chongo/tech/comp/fnv/
  result = 18652614'u32  # -> 2166136261 mod int32.high
  if seed > 0'u32:
    result = seed
  result = result xor uint32(key[0])
  result = result * 16777619'u32
  result = result xor uint32(key[1])
  result = result * 16777619'u32

proc mphLookup(key: array[2, int]): array[3, int32] {.inline, raises: [].} =
  ## Hash map lookup for compositions. Return a
  ## decomposition and its composition
  assert compsHashes.len <= int32.high
  assert compsValues.len <= int32.high
  let d = compsHashes[int(fnv32a(key, 0'u32) mod compsHashes.len)]
  result = compsValues[int(fnv32a(key, d.uint32) mod compsValues.len)]

proc composition*(cpA: int, cpB: int): int {.raises: [].} =
  ## Return the primary composition for
  ## a given decomposition. This is not a full composition.
  ## Return -1 if composition was not found
  assert cpA <= 0x10FFFF
  assert cpB <= 0x10FFFF
  let cps = mphLookup([cpA, cpB])
  if cpA != cps[0] or cpB != cps[1]:
    result = -1
    return
  result = cps[2]

proc composition*(
      cpA: Rune,
      cpB: Rune
    ): Rune {.inline, raises: [ValueError].} =
  ## Return the primary composition for
  ## a given decomposition. This is not a full composition.
  ## Raises `ValueError` if composition was not found
  let cp = composition(int(cpA), int(cpB))
  if cp == -1:
    raise newException(ValueError, "Composition not found")
  result = Rune(cp)

when isMainModule:
  echo(
    (sizeof(compsHashes) +
     sizeof(compsValues)) div 1024)
