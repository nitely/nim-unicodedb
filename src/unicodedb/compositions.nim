## This module provides characters
## composition used by the normalization form algorithms

import unicode

import compositions_data

proc fnv32a(key: array[2, int], seed: int): int {.inline, raises: [].} =
  ## Calculates a distinct hash function for a given sequence
  ## FNV algorithm from http://isthe.com/chongo/tech/comp/fnv/
  const
    fnv32Prime = 16777619
    int32Max = int32.high

  result = 18652614  # -> 2166136261 mod int32Max
  if seed > 0:
    result = seed

  for s in key:
    result = result xor s
    result = (result * fnv32Prime) mod int32Max

proc mphLookup(key: array[2, int]): array[3, int] {.inline, raises: [].} =
  ## Hash map lookup for compositions. Return a
  ## decomposition and its composition
  let d = compsHashes[fnv32a(key, 0) mod compsHashes.len]
  result = compsValues[fnv32a(key, d) mod compsValues.len]

proc composition*(cpA: int, cpB: int): int {.raises: [].} =
  ## Return the primary composition for
  ## a given decomposition. This is not a full composition.
  ## Return -1 if composition was not found
  assert cpA <= 0x10FFFF
  assert cpB <= 0x10FFFF
  let cps = mphLookup([cpA, cpB])
  if cpA != cps[0] or cpB != cps[1]:
    return -1
  result = cps[2]

proc composition*(
      cpA: Rune, cpB: Rune
    ): Rune {.inline, raises: [ValueError].} =
  ## Return the primary composition for
  ## a given decomposition. This is not a full composition.
  ## Raises `ValueError` if composition was not found
  let cp = composition(int(cpA), int(cpB))
  if cp == -1:
    raise newException(ValueError, "Composition not found")
  result = Rune(cp)
