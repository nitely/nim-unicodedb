## This module provides characters
## names lookup and retrieval

import unicode
import strutils

import names_data

const
  sBase = 0xAC00
  lCount = 19
  vCount = 21
  tCount = 28
  nCount = vCount * tCount  # 588
  sCount = lCount * nCount  # 1117
  jamoLTable = [
    "G", "GG", "N", "D", "DD", "R", "M", "B", "BB",
    "S", "SS", "", "J", "JJ", "C", "K", "T", "P", "H"
  ]
  jamoVTable = [
    "A", "AE", "YA", "YAE", "EO", "E", "YEO", "YE", "O",
    "WA", "WAE", "OE", "YO", "U", "WEO", "WE", "WI",
    "YU", "EU", "YI", "I"
  ]
  jamoTTable = [
    "", "G", "GG", "GS", "N", "NJ", "NH", "D", "L", "LG", "LM",
    "LB", "LS", "LT", "LP", "LH", "M", "B", "BS",
    "S", "SS", "NG", "J", "C", "K", "T", "P", "H"
  ]

proc hangulName(r: Rune): string {.inline, raises: [].} =
  ## Hangul name generator. Implementation based on
  ## Unicode standard 10 - Chapter 3
  let sIndex = r.int - sBase
  assert(not (0 > sIndex or sIndex >= sCount))  # Is hangul
  let
    lIndex = sIndex div nCount
    vIndex = (sIndex mod nCount) div tCount
    tIndex = sIndex mod tCount
  result = "HANGUL SYLLABLE "
  result.add(jamoLTable[lIndex])
  result.add(jamoVTable[vIndex])
  result.add(jamoTTable[tIndex])

type
  EPrefixNames {.pure.} = enum
    ## A type for special character ranges
    ## that must generate their name
    ## based on certain rules.
    ## Based on Unicode standard 13 - Chapter 4.8
    Hangul, CJKU, Tangut, Nushu, CJKC, Khitan
const
  prefixNames: array[EPrefixNames, string] = [
    "hangul syllable ".toUpperAscii(),
    "cjk unified ideograph-".toUpperAscii(),
    "tangut ideograph-".toUpperAscii(),
    "nushu character-".toUpperAscii(),
    "cjk compatibility ideograph-".toUpperAscii(),
    "khitan small script character-".toUpperAscii()
  ]
  prefixRanges = [
    (first: 0xAC00, last: 0xD7A3, name: EPrefixNames.Hangul),
    (first: 0x3400, last: 0x4DBF, name: EPrefixNames.CJKU),
    (first: 0x4E00, last: 0x9FFC, name: EPrefixNames.CJKU),
    (first: 0x20000, last: 0x2A6DD, name: EPrefixNames.CJKU),
    (first: 0x2A700, last: 0x2B734, name: EPrefixNames.CJKU),
    (first: 0x2B740, last: 0x2B81D, name: EPrefixNames.CJKU),
    (first: 0x2B820, last: 0x2CEA1, name: EPrefixNames.CJKU),
    (first: 0x2CEB0, last: 0x2EBE0, name: EPrefixNames.CJKU),
    (first: 0x30000, last: 0x3134A, name: EPrefixNames.CJKU),
    (first: 0x17000, last: 0x187F7, name: EPrefixNames.Tangut),
    (first: 0x18D00, last: 0x18D08, name: EPrefixNames.Tangut),
    (first: 0x18B00, last: 0x18CD5, name: EPrefixNames.Khitan),
    (first: 0x1B170, last: 0x1B2FB, name: EPrefixNames.Nushu),
    (first: 0xF900, last: 0xFA6D, name: EPrefixNames.CJKC),
    (first: 0xFA70, last: 0xFAD9, name: EPrefixNames.CJKC),
    (first: 0x2F800, last: 0x2FA1D, name: EPrefixNames.CJKC)
  ]

proc formatHex(cp: int): string {.inline, raises: [].} =
  result = toHex(cp).strip(
    chars = {'0'},
    trailing = false)

proc getNameInPrefixRange(cp: Rune): string {.inline, raises: [].} =
  result = ""
  for pr in prefixRanges:
    if pr.first <= cp.int and cp.int <= pr.last:
      result = prefixNames[pr.name]
      result.add(formatHex(cp.int))
      break

proc name*(cp: Rune): string {.raises: [].} =
  ## Return the name for a given rune.
  ## An empty string is returned if the
  ## rune does not has a name
  assert cp.int <= 0x10FFFF
  if 0xAC00 <= cp.int and cp.int <= 0xD7A3:
    result = hangulName(cp)
    return
  let prName = getNameInPrefixRange(cp)
  if prName.len > 0:
    result = prName
    return
  let
    blockOffset = (namesOffsets[cp.int div blockSize]).int * blockSize
    idx = (namesIndices[blockOffset + cp.int mod blockSize]).int
  if idx == -1:
    result = ""
    return
  let length = namesTable[idx]
  result = newString(length)
  var
    i = 0
    j = 1
    k = 0
  while true:
    let wordOffset = int(wordsOffsets[namesTable[idx+j]])
    k = 0
    while true:
      assert i <= length
      let letter = wordsData[wordOffset+k]
      if letter == 0:
        break
      result[i] = char(letter)
      inc i
      inc k
    if i >= length:
      break
    result[i] = ' '
    inc i  # inc space
    inc j
  assert i == length

proc fnv32a(key: string, seed: uint32): uint32 {.inline, raises: [].} =
  ## Calculates a distinct hash function for a given sequence
  ## FNV algorithm from http://isthe.com/chongo/tech/comp/fnv/
  result = 18652614'u32  # -> 2166136261 mod int32.high
  if seed > 0'u32:
    result = seed
  for s in key:
    result = result xor uint32(s)
    result = result * 16777619'u32

proc mphLookup(key: string): int {.inline, raises: [].} =
  ## Based on minimal perfect hashing algorithm
  assert namesHashes.len <= int32.high
  assert namesValues.len <= int32.high
  let d = namesHashes[(fnv32a(key, 0'u32) mod namesHashes.len).int]
  result = namesValues[(fnv32a(key, d.uint32) mod namesValues.len).int]

# todo: proc lookup*(cpName: string, loose = true): Rune =

proc lookupStrict*(cpName: string): Rune {.raises: [KeyError].} =
  ## Return a rune given its name.
  ## It does a strict matching (i.e not loose).
  ## Raise `KeyError` if not found
  # todo: loose matching: see http://www.unicode.org/reports/tr44/#Matching_Names
  #       requires a second hashes array for the loose mathing
  # todo: support name aliases
  var cp = 0
  for ei, pn in prefixNames:
    if ei == EPrefixNames.Hangul:
      continue
    if cpName.startsWith(pn):
      let rawCp = cpName[pn.len ..< cpName.len]
      try:
        cp = parseHexInt("0x$#" % rawCp)
      except ValueError:
        raise newException(KeyError, "Name not found")
      if cp == -1:  # Hex out of range
        raise newException(KeyError, "Name not found")
      if formatHex(cp) != rawCp:
        raise newException(KeyError, "Name not found")
      result = Rune(cp)
      return
  cp = mphLookup(cpName)
  if cpName != name(cp.Rune):
    raise newException(KeyError, "Name not found")
  result = Rune(cp)

when isMainModule:
  echo(
    (sizeof(namesOffsets) +
     sizeof(namesIndices) +
     sizeof(namesTable) +
     sizeof(wordsOffsets) +
     sizeof(wordsData)) div 1024)
  echo(
    (sizeof(namesHashes) +
     sizeof(namesValues)) div 1024)
