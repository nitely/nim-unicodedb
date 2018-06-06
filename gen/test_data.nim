import unicode
import strutils

import ../src/unicodedb/properties

proc write(path: string, s: string) =
  var f = open(path, fmWrite)
  try:
    f.write(s)
  finally:
    close(f)

const maxCP = 0x10FFFF

proc bidiData(): seq[tuple[cpFirst: int, cpLast: int, bi: string]] =
  result = @[]
  var lastData = 0.Rune.bidirectional()
  var lastCP = 0
  for cp in 0 .. maxCP:
    let data = cp.Rune.bidirectional()
    if data != lastData:
      result.add((cpFirst: lastCP, cpLast: cp-1, bi: lastData))
      lastData = data
      lastCP = cp
  result.add((cpFirst: lastCP, cpLast: maxCP, bi: lastData))

const bidiTemplate = """const allBidis* = [
$#]
"""

proc categoryData(): seq[tuple[cpFirst: int, cpLast: int, cat: string]] =
  result = @[]
  var lastData = 0.Rune.category()
  var lastCP = 0
  for cp in 0 .. maxCP:
    let data = cp.Rune.category()
    if data != lastData:
      result.add((cpFirst: lastCP, cpLast: cp-1, cat: lastData))
      lastData = data
      lastCP = cp
  result.add((cpFirst: lastCP, cpLast: maxCP, cat: lastData))

const catTemplate = """const allCats* = [
$#]
"""

proc isAssigned(r: Rune): bool =
  r.category() != "Cn"

proc combiningData(): seq[tuple[
    cpFirst: int,
    cpLast: int,
    ccc: int,
    assigned: bool]] =
  result = @[]
  var lastData = 0.Rune.combining()
  var lastAssigned = 0.Rune.isAssigned()
  var lastCP = 0
  for cp in 0 .. maxCP:
    let data = cp.Rune.combining()
    let assigned = cp.Rune.isAssigned()
    if data != lastData or assigned != lastAssigned:
      result.add((
        cpFirst: lastCP,
        cpLast: cp-1,
        ccc: lastData,
        assigned: lastAssigned))
      lastData = data
      lastAssigned = assigned
      lastCP = cp
  result.add((
    cpFirst: lastCP,
    cpLast: maxCP,
    ccc: lastData,
    assigned: lastAssigned))

const combiningTemplate = """const allCombining* = [
$#]
"""

when isMainModule:
  var bidi = ""
  for d in bidiData():
    bidi.add(' ')
    bidi.add(' ')
    bidi.add($d)
    bidi.add(',')
    bidi.add('\L')
  write("./tests/bidi_test_data.nim", bidiTemplate % bidi)
  var cat = ""
  for d in categoryData():
    cat.add(' ')
    cat.add(' ')
    cat.add($d)
    cat.add(',')
    cat.add('\L')
  write("./tests/category_test_data.nim", catTemplate % cat)
  var comb = ""
  for d in combiningData():
    comb.add(' ')
    comb.add(' ')
    comb.add($d)
    comb.add(',')
    comb.add('\L')
  write("./tests/combining_test_data.nim", combiningTemplate % comb)


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
