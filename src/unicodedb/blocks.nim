import std/strutils
import std/unicode

import ./blocks_data

type
  UnicodeDbBlock* = distinct Slice[int]

proc rangesFor(name: string): seq[UnicodeDbBlock] {.compileTime.} =
  result = newSeq[UnicodeDbBlock]()
  for i, n in blockNames.pairs:
    if name in n:
      result.add blockRanges[i].UnicodeDbBlock

template rangesForTpl(name: untyped): untyped =
  block:
    var org {.compileTime.} = rangesFor(name)
    var dest {.compileTime.}: array[org.len, UnicodeDbBlock]
    for i in 0 .. org.len-1:
      dest[i] = org[i]
    dest

const
  blockTangut* = rangesForTpl("Tangut")
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
