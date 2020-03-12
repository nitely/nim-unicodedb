import strtabs
import strutils

import unicode_data
import two_stage_table
import min_perfect_hash
import utils

# See http://www.unicode.org/versions/latest/ch04.pdf
# Chapter 4.8
const
  prefixRanges = [
    [0xAC00, 0xD7A3],
    [0x3400, 0x4DBF],
    [0x4E00, 0x9FFC],
    [0x20000, 0x2A6DD],
    [0x2A700, 0x2B734],
    [0x2B740, 0x2B81D],
    [0x2B820, 0x2CEA1],
    [0x2CEB0, 0x2EBE0],
    [0x30000, 0x3134A],
    [0x17000, 0x187F7],
    [0x18D00, 0x18D08],
    [0x18B00, 0x18CD5],
    [0x1B170, 0x1B2FB],
    [0xF900, 0xFA6D],
    [0xFA70, 0xFAD9],
    [0x2F800, 0x2FA1D]
  ]

proc isInPrefixRange(cp: int): bool =
  result = false
  for pr in prefixRanges:
    if pr[0] <= cp and cp <= pr[1]:
      result = true
      break

proc parseNames(namesRaw: seq[string]): seq[string] =
  result = newSeq[string](namesRaw.len)
  for cp, nr in namesRaw:
    if nr.len == 0:
      continue
    # These can be auto generated,
    # so we don't store them
    if isInPrefixRange(cp):
      continue
    # Un-named
    if nr.startsWith("<") and nr.endswith(">"):
      continue
    result[cp] = nr

# See http://www.unicode.org/versions/latest/ch03.pdf#M9.32468.Heading.310.Combining.Jamo.Behavior
const
  SBase = 0xAC00
  LBase = 0x1100
  VBase = 0x1161
  TBase = 0x11A7
  LCount = 19
  VCount = 21
  TCount = 28
  NCount = VCount * TCount  # 588
  SCount = LCount * NCount  # 11172

const
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

# todo: move hangulName from src/unicodedbpkg/names to src/unicodedbpkg/hangul
#       and import that, then remove this.
proc hangulName(s: int): string =
  let SIndex = s - SBase
  if 0 > SIndex or SIndex >= SCount:
    raise newException(
      ValueError, "Not a Hangul Syllable: $#" % [intToStr(s)])
  let LIndex = SIndex div NCount
  let VIndex = (SIndex mod NCount) div TCount
  let TIndex = SIndex mod TCount
  result = "HANGUL SYLLABLE "
  result.add(jamoLTable[LIndex])
  result.add(jamoVTable[VIndex])
  result.add(jamoTTable[TIndex])

proc buildWords(names: seq[string]): seq[string] =
  ## Return unique words
  result = @[]
  var wordsLookup = newStringTable(modeCaseSensitive)
  for cp, name in names:
    if name.len == 0:
      continue
    for word in name.split(' '):
      if wordsLookup.hasKey(word):
        continue
      result.add(word)
      wordsLookup[word] = ""

type
  WordsTable = ref object
    words: seq[int]
    offsets: seq[int]

proc buildWordsTable(words: seq[string]): WordsTable =
  ## build giant array of null-terminated words and
  ## an offset table to track where each word starts
  var tableSize = 0
  for word in words:
    tableSize += len(word) + 1

  result = WordsTable(
    words: newSeq[int](tableSize),
    offsets: newSeq[int](words.len))
  var offset = 0
  for i, word in words:
    result.offsets[i] = offset
    for c in word:
      result.words[offset] = ord(c)
      inc offset
    result.words[offset] = 0
    inc offset

type
  NamesTable = ref object
    names: seq[int]
    offsets: seq[int]

proc buildNamesTable(names: seq[string], words: seq[string]): NamesTable =
  ## Return table for retrieving a name from a CP.
  ## Build table of name-words idx mapping and table of offsets cp-name.
  ## -> [lenA, wordAIdx, wordBIdx, lenB...]
  var maxNamesSize = 0
  for name in names:
    if name.len == 0:
      continue
    for word in name.split(' '):
      inc maxNamesSize
    inc maxNamesSize

  result = NamesTable(
    names: newSeqOfCap[int](maxNamesSize),
    offsets: newSeq[int](names.len))
  for i in 0 ..< result.offsets.len:
    result.offsets[i] = -1

  # todo: use table
  var wordsLookup = newStringTable(modeCaseSensitive)
  for i, word in words:
    wordsLookup[word] = intToStr(i)

  var nameLookup = newStringTable(modeCaseSensitive)
  var offset = 0
  var dedupsCount = 0
  for cp, name in names:
    if name.len == 0:
      continue
    # De-duplicate name
    let nl = nameLookup.getOrDefault(name, "")
    if nl.len > 0:
      inc dedupsCount
      result.offsets[cp] = result.offsets[parseInt(nl)]
      continue
    nameLookup[name] = intToStr(cp)

    result.offsets[cp] = offset
    result.names.add(name.len)
    inc offset
    for word in name.split(' '):
      result.names.add(parseInt(wordsLookup[word]))
      inc offset
  echo "dedups: $#" % $dedupsCount

proc buildNameLookup(namesRaw: seq[string]): seq[Record[int]] =
  ## Return lookup tables for retrieving a CP from a name
  result = newSeqOfCap[Record[int]](namesRaw.len)
  for cp, nr in namesRaw:
    if nr.len == 0:
      continue
    var rd = (
      key: newSeq[int](nr.len),
      value: cp)
    for i, c in nr:
      rd.key[i] = ord(c)
    result.add(rd)
  # Add Hangul Syllables
  for cp in 0xAC00 .. 0xD7A3:
    let nr = hangulName(cp)
    var rd = (
      key: newSeq[int](nr.len),
      value: cp)
    for i, c in nr:
      rd.key[i] = ord(c)
    result.add(rd)

const namesTemplate = """## This is auto-generated. Do not modify it

const
  namesOffsets* = [
    $#
  ]
  namesIndices* = [
    $#
  ]
  namesTable* = [
    $#
  ]
  wordsOffsets* = [
    $#
  ]
  wordsData* = [
    $#
  ]
  blockSize* = $#

  namesHashes* = [
    $#
  ]
  namesValues* = [
    $#
  ]
"""

when isMainModule:
  echo "unicode data"
  let names = parseNames(parseUDNames("./gen/UCD/UnicodeData.txt"))
  echo "words"
  let words = buildWords(names)
  echo "words Table"
  let wtObj = buildWordsTable(words)
  echo len(wtObj.words)
  echo len(wtObj.offsets)
  echo "names Table"
  let ntObj = buildNamesTable(names, words)
  echo len(ntObj.names)
  echo len(ntObj.offsets)
  echo "done"
  echo "two stage table"
  let stageTable = findBestTable(ntObj.offsets)
  assert stageTable.blockSize > 0
  echo stageTable.blockSize
  echo len(stageTable.stage1)
  echo len(stageTable.stage2)

  # todo: has to check the returned CP matches the given name (the reverse)
  var mphTables = mph(buildNameLookup(names))
  #var fooNameInts: seq[int] = @[]
  #for c in "LATIN CAPITAL LETTER C WITH DOT ABOVE":
  #  fooNameInts.add(ord(c))
  #echo mphLookup(mphTables.h, mphTables.v, fooNameInts)

  var f = open("./src/unicodedb/names_data.nim", fmWrite)
  try:
    f.write(namesTemplate % [
      prettyTable(stageTable.stage1, 15, "'u8"),
      prettyTable(stageTable.stage2, 5, "'i32"),
      prettyTable(ntObj.names, 10, "'i16"),
      prettyTable(wtObj.offsets, 10, "'i32"),
      prettyTable(wtObj.words, 15, "'i8"),
      intToStr(stageTable.blockSize),
      prettyTable(mphTables.h, 15, "'u16"),
      prettyTable(mphTables.v, 10, "'i32")
    ])
  finally:
    close(f)
