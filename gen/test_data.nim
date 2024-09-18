import std/unicode
import std/strutils
import std/sequtils

import ../src/unicodedb/properties
import ../src/unicodedb/compositions
import ../src/unicodedb/decompositions
import ../src/unicodedb/types
import ../src/unicodedb/casing
import ../src/unicodedb/segmentation

proc write(path: string, s: string) =
  var f = open(path, fmWrite)
  try:
    f.write(s)
  finally:
    close(f)

proc isAssigned(r: Rune): bool =
  r.unicodeCategory() != ctgCn

const maxCP = 0x10FFFF

proc bidiData(): seq[tuple[cpFirst: int, cpLast: int, bi: string, assigned: bool]] =
  result = @[]
  var lastData = 0.Rune.bidirectional()
  var lastCP = 0
  var lastAssigned = 0.Rune.isAssigned()
  for cp in 0 .. maxCP:
    let data = cp.Rune.bidirectional()
    let assigned = cp.Rune.isAssigned()
    if data != lastData or assigned != lastAssigned:
      result.add((
        cpFirst: lastCP,
        cpLast: cp-1,
        bi: lastData,
        assigned: lastAssigned))
      lastData = data
      lastAssigned = assigned
      lastCP = cp
  result.add((
    cpFirst: lastCP,
    cpLast: maxCP,
    bi: lastData,
    assigned: lastAssigned))

const bidiTemplate = """const allBidis* = [
$#]
"""

proc categoryData(): seq[tuple[cpFirst: int, cpLast: int, cat: UnicodeCategory]] =
  result = @[]
  var lastData = 0.Rune.unicodeCategory()
  var lastCP = 0
  for cp in 0 .. maxCP:
    let data = cp.Rune.unicodeCategory()
    if data != lastData:
      result.add((cpFirst: lastCP, cpLast: cp-1, cat: lastData))
      lastData = data
      lastCP = cp
  result.add((cpFirst: lastCP, cpLast: maxCP, cat: lastData))

const catTemplate = """const allCats* = [
$#]
"""

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

proc typesData(): seq[tuple[
    first: int,
    last: int,
    de: bool,
    di: bool,
    nu: bool,
    lo: bool,
    up: bool,
    asig: bool]] =
  #[
  utmDecimal = 1
  utmDigit = 2
  utmNumeric = 4
  utmLowercase = 8
  utmUppercase = 16
  utmCased = 32
  utmWhiteSpace = 64
  utmWord = 128
  ]#
  result = @[]
  let t = 0.Rune.unicodeTypes()
  var lastData = [
    utmDecimal in t,
    utmDigit in t,
    utmNumeric in t,
    utmLowercase in t,
    utmUppercase in t,
    0.Rune.isAssigned()]
  var lastCP = 0
  for cp in 0 .. maxCP:
    let t = cp.Rune.unicodeTypes()
    let data = [
      utmDecimal in t,
      utmDigit in t,
      utmNumeric in t,
      utmLowercase in t,
      utmUppercase in t,
      cp.Rune.isAssigned()]
    if data != lastData:
      result.add((
        first: lastCP,
        last: cp-1,
        de: lastData[0],
        di: lastData[1],
        nu: lastData[2],
        lo: lastData[3],
        up: lastData[4],
        asig: lastData[5]))
      lastData = data
      lastCP = cp
  result.add((
    first: lastCP,
    last: maxCP,
    de: lastData[0],
    di: lastData[1],
    nu: lastData[2],
    lo: lastData[3],
    up: lastData[4],
    asig: lastData[5]))

const typesTemplate = """const allTypes* = [
$#]
"""

type
  Casing = tuple
    cp: int
    cps: seq[int]

template casingData(conversion): untyped {.dirty.} =
  for cp in 0 .. maxCP:
    let cps = toSeq(conversion(cp.Rune))
    if cps.len > 1:
      result.add((
        cp: cp,
        cps: map(cps, proc (x: Rune): int = x.int)
      ))
    elif cps.len == 1 and cps[0] != cp.Rune:
      result.add((cp: cp, cps: @[cps[0].int]))

proc lowercaseData(): seq[Casing] =
  casingData(lowerCase)

proc uppercaseData(): seq[Casing] =
  casingData(upperCase)

proc titlecaseData(): seq[Casing] =
  casingData(titleCase)

proc casefoldData(): seq[Casing] =
  casingData(caseFold)

const casingTemplate = """const allLowercase* = [
$#]
const allUppercase* = [
$#]
const allTitlecase* = [
$#]
const allCasefold* = [
$#]
"""

type
  WordBreak = tuple
    cpFirst: int
    cpLast: int
    prop: int

proc wordBreakData(): seq[WordBreak] =
  result = @[]
  var lastData = 0.Rune.wordBreakProp.int
  var lastCP = 0
  for cp in 0 .. maxCP:
    let data = cp.Rune.wordBreakProp.int
    if data != lastData:
      result.add((cpFirst: lastCP, cpLast: cp-1, prop: lastData))
      lastData = data
      lastCP = cp
  result.add((cpFirst: lastCP, cpLast: maxCP, prop: lastData))

const wordBreakTemplate = """const allWordBreak* = [
$#]
"""

proc `$`(uctg: UnicodeCategory): string =
  $uctg.int

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
  echo "Generating types data"
  var ts = ""
  for d in typesData():
    ts.add(' ')
    ts.add(' ')
    ts.add($d)
    ts.add(',')
    ts.add('\L')
  write("./tests/types_test_data.nim", typesTemplate % ts)
  echo "Generating casing data"
  var lowercaseTpl = ""
  for ca in lowercaseData():
    lowercaseTpl.add(' ')
    lowercaseTpl.add(' ')
    lowercaseTpl.add($ca)
    lowercaseTpl.add(',')
    lowercaseTpl.add('\L')
  var uppercaseTpl = ""
  for ca in uppercaseData():
    uppercaseTpl.add(' ')
    uppercaseTpl.add(' ')
    uppercaseTpl.add($ca)
    uppercaseTpl.add(',')
    uppercaseTpl.add('\L')
  var titlecaseTpl = ""
  for ca in titlecaseData():
    titlecaseTpl.add(' ')
    titlecaseTpl.add(' ')
    titlecaseTpl.add($ca)
    titlecaseTpl.add(',')
    titlecaseTpl.add('\L')
  var casefoldTpl = ""
  for ca in casefoldData():
    casefoldTpl.add(' ')
    casefoldTpl.add(' ')
    casefoldTpl.add($ca)
    casefoldTpl.add(',')
    casefoldTpl.add('\L')
  write(
    "./tests/casing_test_data.nim", casingTemplate % [
      lowercaseTpl, uppercaseTpl, titlecaseTpl, casefoldTpl])
  var wordBreakTpl = ""
  for wb in wordBreakData():
    wordBreakTpl.add(' ')
    wordBreakTpl.add(' ')
    wordBreakTpl.add($wb)
    wordBreakTpl.add(',')
    wordBreakTpl.add('\L')
  write(
    "./tests/word_break_test_data.nim", wordBreakTemplate % wordBreakTpl)
