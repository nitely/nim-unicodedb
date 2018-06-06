import unicode
import strutils

import ../src/unicodedb/properties

const maxCP = 0x10FFFF

proc bidiData(): seq[tuple[cpFirst: int, cpLast: int, bi: string]] =
  result = @[]
  var lastData = 0.Rune.bidirectional()
  var lastCP = 0
  for cp in 0 .. maxCP:
    let bidi = cp.Rune.bidirectional()
    if bidi != lastData:
      result.add((cpFirst: lastCP, cpLast: cp-1, bi: lastData))
      lastData = bidi
      lastCP = cp
  result.add((cpFirst: lastCP, cpLast: maxCP, bi: lastData))

proc write(path: string, s: string) =
  var f = open(path, fmWrite)
  try:
    f.write(s)
  finally:
    close(f)

const bidiTemplate = """const allBidis* = [
$#]
"""

when isMainModule:
  var bidi = ""
  for b in bidiData():
    bidi.add(' ')
    bidi.add(' ')
    bidi.add($b)
    bidi.add(',')
    bidi.add('\L')
  write("./tests/bidi_test_data.nim", bidiTemplate % bidi)


#[

res = []
last_cat = getData(0)
last_cp = 0
for cp in range(0x10FFFF+1):
    if getData(cp) != last_cat:
        res.append((last_cp, cp - 1, *last_cat))
        last_cat = getData(cp)
        last_cp = cp
res.append((last_cp, cp, *last_cat))

with open('./out', 'w') as fh:
    for cp in res:
        fh.write('  (first: %d, last: %d, de: %s, di: %s, nu: %s, lo: %s, up: %s, asig: %s),' % cp)
        fh.write('\n')


]#
