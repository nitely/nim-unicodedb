import std/strutils
import std/unicode

import ./blocks_data

type
  UnicodeDbBlock* = distinct Slice[int]

proc rangesFor(name: string, fullName: bool): seq[UnicodeDbBlock] {.compileTime.} =
  result = newSeq[UnicodeDbBlock]()
  if fullName:
    for i, n in blockNames.pairs:
      if name == n:
        result.add blockRanges[i].UnicodeDbBlock
  else:
    for i, n in blockNames.pairs:
      if name in n:
        result.add blockRanges[i].UnicodeDbBlock

template rangesForTpl(name: string, fullName = false): untyped =
  block:
    var org {.compileTime.} = rangesFor(name, fullName)
    var dest {.compileTime.}: array[org.len, UnicodeDbBlock]
    for i in 0 .. org.len-1:
      dest[i] = org[i]
    dest

const
  blockTangut* = rangesForTpl("Tangut", fullName = true)
  blockTangutComponents* = rangesForTpl("Tangut Components", fullName = true)
  blockTangutSupplement* = rangesForTpl("Tangut Supplement", fullName = true)
  blockTangutComponentsSupplement* = rangesForTpl("Tangut Components Supplement", fullName = true)
  blockNushu* = rangesForTpl("Nushu")
  blockKhitan* = rangesForTpl("Khitan Small Script")
  blockHanUnif* = rangesForTpl("CJK Unified Ideographs")
  blockHanCompat* = rangesForTpl("CJK Compatibility Ideographs")

proc contains(a: UnicodeDbBlock; item: int): bool {.borrow.}

proc contains(a: openArray[UnicodeDbBlock], item: int): bool {.inline.} =
  result = false
  for r in a:
    if item in r:
      return true

proc contains*(a: openArray[UnicodeDbBlock], item: Rune): bool =
  contains(a, item.int)

when isMainModule:
  # nim c -r src/unicodedb/blocks.nim
  echo blockTangut
