## This module provides international character
## order (collation) for unicode runes reflecting
## the DUCET standards database

import 
  std / algorithm,
  std / unicode,
  std / strutils,
  std / tables

import collation_data
export CollationElement

type
  SortKey* = seq[uint16]

proc elementArray*(r: Rune): seq[CollationElement] =
  result = rawCollations.getOrDefault(r)

proc generateCollationElementArray(s: string): seq[CollationElement] =
  # the string MUST be normalized first
  discard # Much TODO

proc generateSortKey(cea: seq[CollationElement]): SortKey =
  discard # Much TODO

proc sortKey*(s: string): SortKey =
  # see https://unicode.org/reports/tr10/#Main_Algorithm
  # the string MUST be normalized first
  let cea = generateCollationElementArray(s)
  result = generateSortKey(cea)

proc sortKeyCmp*(a: SortKey, b: SortKey): int =
  # -1 = a < b
  #  0 = equal
  # +1 = a > b
  let smallerLen = min(a.len, b.len)
  for index in 0 ..< smallerLen:
    let c = cmp(a[index], b[index])
    if c != 0:
      return c
  if a.len < b.len:
    return 1   # a is shorter, so a is greater
  else:
    return -1  # b is shorter, so b is greater

proc unicodeCmp*(a: string, b: string): int =
  # the strings MUST be normalized first
  let sa = a.sortKey
  let sb = b.sortKey
  result = sortKeyCmp(sa, sb)

proc unicodeEqual*(a: string, b: string): bool =
  # the strings MUST be normalized first
  if unicodeCmp(a, b) == 0:
    result = true
  else:
    result = false

proc unicodeSort*(stringList: var seq[string], order = SortOrder.Ascending) =
  # the strings MUST be normalized first
  sort(stringList, unicodeCmp, order)

proc unicodeSorted*(stringList: seq[string], order = SortOrder.Ascending): seq[string] =
  # the strings MUST be normalized first
  result = sorted(stringList, unicodeCmp, order)
