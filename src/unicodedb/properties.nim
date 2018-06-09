## This module provides common characters
## properties: category class, canonical
## combining class, bidirectional class and quick check (QC)

import unicode

import properties_data

export
  NfMask,
  UnicodeCategory,
  ctgLm,
  ctgLo,
  ctgLu,
  ctgLl,
  ctgLt,
  ctgMn,
  ctgMc,
  ctgMe,
  ctgNd,
  ctgNl,
  ctgNo,
  ctgZs,
  ctgZl,
  ctgZp,
  ctgCc,
  ctgCf,
  ctgCs,
  ctgCo,
  ctgCn,
  ctgPc,
  ctgPd,
  ctgPs,
  ctgPe,
  ctgPi,
  ctgPf,
  ctgPo,
  ctgSm,
  ctgSc,
  ctgSk,
  ctgSo

type
  UnicodeCategorySet* = distinct int32
    ## A set of ``UnicodeCategory`` elements

proc contains*(a: UnicodeCategorySet, b: UnicodeCategory): bool {.inline.} =
  ## Check if the given category is
  ## within the categories.
  ##
  ## .. code-block:: nim
  ##   assert Rune(0x0097).category() in ctgL
  ##
  result = (b.int and a.int) != 0

template ucPlusImpl(a, b): UnicodeCategorySet =
  UnicodeCategorySet(int32(a) or int32(b))
proc `+`*(
    a: UnicodeCategorySet,
    b: UnicodeCategory): UnicodeCategorySet {.inline.} =
  ucPlusImpl(a, b)
proc `+`*(
    a: UnicodeCategory,
    b: UnicodeCategorySet): UnicodeCategorySet {.inline.} =
  ucPlusImpl(a, b)
proc `+`*(a, b: UnicodeCategorySet): UnicodeCategorySet {.inline.} =
  ucPlusImpl(a, b)
proc `+`*(a, b: UnicodeCategory): UnicodeCategorySet {.inline.} =
  ucPlusImpl(a, b)

proc `==`*(a, b: UnicodeCategory): bool {.inline.} =
  result = (a.int and b.int) != 0

const
  ctgL* = ctgLm + ctgLo + ctgLu + ctgLl + ctgLt
  ctgM* = ctgMn + ctgMc + ctgMe
  ctgN* = ctgNd + ctgNl + ctgNo
  ctgZ* = ctgZs + ctgZl + ctgZp
  ctgC* = ctgCc + ctgCf + ctgCs + ctgCo + ctgCn
  ctgP* = ctgPc + ctgPd + ctgPs + ctgPe + ctgPi + ctgPf + ctgPo
  ctgS* = ctgSm + ctgSc + ctgSk + ctgSo

proc categorySetMap*(s: string): UnicodeCategorySet =
  ## Map category string to ``UnicodeCategorySet``.
  ## Raise ``ValueError`` if there's no match
  # todo: result = .. is needed in Nim 0.18 to work at compile time
  case s
  of "L":
    result = ctgL
  of "M":
    result = ctgM
  of "N":
    result = ctgN
  of "Z":
    result = ctgZ
  of "C":
    result = ctgC
  of "P":
    result = ctgP
  of "S":
    result = ctgS
  else:
    raise newException(ValueError, "Bad category")

proc categoryMap*(s: string): UnicodeCategory =
  ## Map category string to ``UnicodeCategory``.
  ## Raise ``ValueError`` if there's no match
  # todo: result = .. is needed in Nim 0.18 to work at compile time
  case s
  of "Lm":
    result = ctgLm
  of "Lo":
    result = ctgLo
  of "Lu":
    result = ctgLu
  of "Ll":
    result = ctgLl
  of "Lt":
    result = ctgLt
  of "Mn":
    result = ctgMn
  of "Mc":
    result = ctgMc
  of "Me":
    result = ctgMe
  of "Nd":
    result = ctgNd
  of "Nl":
    result = ctgNl
  of "No":
    result = ctgNo
  of "Zs":
    result = ctgZs
  of "Zl":
    result = ctgZl
  of "Zp":
    result = ctgZp
  of "Cc":
    result = ctgCc
  of "Cf":
    result = ctgCf
  of "Cs":
    result = ctgCs
  of "Co":
    result = ctgCo
  of "Cn":
    result = ctgCn
  of "Pc":
    result = ctgPc
  of "Pd":
    result = ctgPd
  of "Ps":
    result = ctgPs
  of "Pe":
    result = ctgPe
  of "Pi":
    result = ctgPi
  of "Pf":
    result = ctgPf
  of "Po":
    result = ctgPo
  of "Sm":
    result = ctgSm
  of "Sc":
    result = ctgSc
  of "Sk":
    result = ctgSk
  of "So":
    result = ctgSo
  else:
    raise newException(ValueError, "Bad category")

type
  UnicodeProp* = enum
    ## A type for getting a single
    ## property from the `Props` type
    upropCat  # Category
    upropCcc  # Combining class
    upropBi  # Bidirectional
    upropQc  # QuikCheck

  UnicodeProps* = array[UnicodeProp, int32]
    ## A type holding all common
    ## properties for a character.
    ## Use `UnicodeProp` to get one of them.
    ## It contains raw data for some of them.

proc properties*(cp: Rune): UnicodeProps =
  ## Return properties for a given code point.
  ## Includes: Category, Canonical Combining Class,
  ## Bidi Class and QC. This may be used as an optimization
  ## when more than one property is required. This contains
  ## raw data for some of the properties, so one of
  ## the auxiliary procedures must be used in conjuntion.
  assert cp.int <= 0x10FFFF
  let
    blockOffset = (propsOffsets[cp.int div blockSize]).int * blockSize
    idx = propsIndices[blockOffset + cp.int mod blockSize]
  result = propsData[idx]

proc properties*(cp: int): UnicodeProps {.deprecated.} =
  ## **Deprecated since version 0.3.0**;
  ## Use ``properties(Rune)`` instead.
  properties(cp.Rune)

proc unicodeCategory*(props: UnicodeProps): UnicodeCategory {.inline.} =
  ## Return category for a given `UnicodeProps`
  result = props[upropCat].UnicodeCategory

proc unicodeCategory*(cp: Rune): UnicodeCategory {.inline.} =
  ## Return category for a given code point
  cp.properties.unicodeCategory

proc categoryMap(s: UnicodeCategory): string =
  case s
  of ctgLm:
    "Lm"
  of ctgLo:
    "Lo"
  of ctgLu:
    "Lu"
  of ctgLl:
    "Ll"
  of ctgLt:
    "Lt"
  of ctgMn:
    "Mn"
  of ctgMc:
    "Mc"
  of ctgMe:
    "Me"
  of ctgNd:
    "Nd"
  of ctgNl:
    "Nl"
  of ctgNo:
    "No"
  of ctgZs:
    "Zs"
  of ctgZl:
    "Zl"
  of ctgZp:
    "Zp"
  of ctgCc:
    "Cc"
  of ctgCf:
    "Cf"
  of ctgCs:
    "Cs"
  of ctgCo:
    "Co"
  of ctgCn:
    "Cn"
  of ctgPc:
    "Pc"
  of ctgPd:
    "Pd"
  of ctgPs:
    "Ps"
  of ctgPe:
    "Pe"
  of ctgPi:
    "Pi"
  of ctgPf:
    "Pf"
  of ctgPo:
    "Po"
  of ctgSm:
    "Sm"
  of ctgSc:
    "Sc"
  of ctgSk:
    "Sk"
  of ctgSo:
    "So"
  else:
    assert false
    ""

proc category*(props: UnicodeProps): string {.deprecated, inline.} =
  ## **Deprecated since version 0.4.1**;
  ## Use ``unicodeCategory(UnicodeProps)`` instead.
  result = props[upropCat].UnicodeCategory.categoryMap()

proc category*(cp: int): string {.deprecated.} =
  ## **Deprecated since version 0.3.0**;
  ## Use ``unicodeCategory(Rune)`` instead.
  category(properties(cp))

proc category*(cp: Rune): string {.deprecated, inline.} =
  ## **Deprecated since version 0.4.1**;
  ## Use ``unicodeCategory(Rune)`` instead.
  category(properties(cp))

proc bidirectional*(props: UnicodeProps): string {.inline.} =
  ## Return bidirectional class name for a given `UnicodeProps`
  result = bidirectionalNames[props[upropBi]]

proc bidirectional*(cp: int): string {.deprecated.} =
  ## **Deprecated since version 0.3.0**;
  ## Use ``bidirectional(Rune)`` instead.
  bidirectional(properties(cp))

proc bidirectional*(cp: Rune): string {.inline.} =
  ## Return bidirectional class name for a given code point
  bidirectional(properties(cp))

proc combining*(props: UnicodeProps): int {.inline.} =
  ## Return canonical combining class property
  ## for a given `Props`
  result = props[upropCcc]

proc combining*(cp: int): int {.deprecated.} =
  ## **Deprecated since version 0.3.0**;
  ## Use ``bidirectional(Rune)`` instead.
  combining(properties(cp))

proc combining*(cp: Rune): int {.inline.} =
  ## Return canonical combining class property
  ## for a given code point
  combining(properties(cp))

proc quickCheck*(props: UnicodeProps): int {.inline.} =
  ## Return quick check property for a given `UnicodeProps`
  result = props[upropQc]

proc quickCheck*(cp: int): int {.deprecated.} =
  ## **Deprecated since version 0.3.0**;
  ## Use ``quickCheck(Rune)`` instead.
  quickCheck(properties(cp))

proc quickCheck*(cp: Rune): int {.inline.} =
  ## Return quick check property
  quickCheck(properties(cp))

proc contains*(qc: int, m: NfMask): bool =
  ## Check if the given NF mask is
  ## within the quick-check values.
  ##
  ## .. code-block:: nim
  ##   assert nfcQcNo in Rune(0x0374).quickCheck()
  ##
  result = (qc and m.ord) != 0

when isMainModule:
  echo(
    (sizeof(propsOffsets) +
     sizeof(propsIndices) +
     sizeof(propsData)) div 1024)
