import unicode
import strutils

import ../src/unicodedb/properties
import ../src/unicodedb/compositions
import ../src/unicodedb/decompositions

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

proc compositionData(): seq[array[3, int]] =
  result = @[]
  var comp = 0.Rune
  for cp in 0 .. maxCP:
    let decomp = canonicalDecomposition(cp.Rune)
    if decomp.len == 2:
      if composition(comp, decomp[0], decomp[1]):
        result.add([cp, decomp[0].int, decomp[1].int])
        assert comp == cp.Rune

const compositionTemplate = """const allComps* = [
$#]
"""

proc decompositionData(): seq[tuple[
    cp: int,
    isCanonical: bool,
    dcp: seq[int]]] =
  result = @[]
  for cp in 0 .. maxCP:
    let decomp = decomposition(cp.Rune)
    if decomp.len > 0:
      var decompInt = newSeq[int]()
      for dcp in decomp:
        decompInt.add(dcp.int)
      result.add((
        cp: cp,
        isCanonical: canonicalDecomposition(cp.Rune).len > 0,
        dcp: decompInt))

const decompositionTemplate = """const allDecomps* = [
$#]
"""

when isMainModule:
  echo "Generating bidirectional data"
  var bidi = ""
  for d in bidiData():
    bidi.add(' ')
    bidi.add(' ')
    bidi.add($d)
    bidi.add(',')
    bidi.add('\L')
  write("./tests/bidi_test_data.nim", bidiTemplate % bidi)
  echo "Generating category data"
  var cat = ""
  for d in categoryData():
    cat.add(' ')
    cat.add(' ')
    cat.add($d)
    cat.add(',')
    cat.add('\L')
  write("./tests/category_test_data.nim", catTemplate % cat)
  echo "Generating combining data"
  var comb = ""
  for d in combiningData():
    comb.add(' ')
    comb.add(' ')
    comb.add($d)
    comb.add(',')
    comb.add('\L')
  write("./tests/combining_test_data.nim", combiningTemplate % comb)
  echo "Generating compositions data"
  var comp = ""
  for d in compositionData():
    comp.add(' ')
    comp.add(' ')
    comp.add($d)
    comp.add(',')
    comp.add('\L')
  write("./tests/compositions_test_data.nim", compositionTemplate % comp)
  echo "Generating decompositions data"
  var decomp = ""
  for d in decompositionData():
    decomp.add(' ')
    decomp.add(' ')
    decomp.add($d)
    decomp.add(',')
    decomp.add('\L')
  write("./tests/decompositions_test_data.nim", decompositionTemplate % decomp)
