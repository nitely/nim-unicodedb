import std/strscans
import std/strutils
import std/algorithm

type
  Block = object
    name: string
    bounds: Slice[int]

proc parse(filePath: string): seq[Block] =
  result = newSeq[Block]()
  var name: string
  var first, last: int
  for line in filePath.lines:
    if scanf(line, "$h..$h; $*", first, last, name):
      result.add Block(name: name, bounds: first..last)
    else:
      doAssert line.startsWith("#") or line.len == 0
  #result.sort do (x, y: Block) -> int:
  #  result = cmp(x.a, y.a)

const templ = """## This is auto-generated. Do not modify it

const
  blockNames* = [
    $#
  ]
  blockRanges* = [
    $#
  ]

"""

when isMainModule:
  let blocks = parse("./gen/UCD/Blocks.txt")
  var names = newSeq[string]()
  var rangs = newSeq[string]()
  for b in blocks:
    names.add "\"$#\"" % b.name
    rangs.add "$#..$#" % [$b.bounds.a, $b.bounds.b]
  var f = open("./src/unicodedb/blocks_data.nim", fmWrite)
  try:
    f.write(templ % [
      join(names, ",\L    "),
      join(rangs, ",\L    ")])
  finally:
    close(f)
