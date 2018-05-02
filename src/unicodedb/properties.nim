## This module provides common characters
## properties: category class, canonical
## combining class, bidirectional class and quick check (QC)

import unicode

import properties_data

export NfMask

type
  UnicodeProp* = enum
    ## A type for getting a single
    ## property from the `Props` type
    upropCat  # Category
    upropCcc  # Combining class
    upropBi  # Bidirectional
    upropQc  # QuikCheck

  UnicodeProps* = array[UnicodeProp, int16]
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

proc category*(props: UnicodeProps): string {.inline.} =
  ## Return category property name for a given `UnicodeProps`
  result = categoryNames[props[upropCat]]

proc category*(cp: int): string {.deprecated.} =
  ## **Deprecated since version 0.3.0**;
  ## Use ``category(Rune)`` instead.
  category(properties(cp))

proc category*(cp: Rune): string {.inline.} =
  ## Return category property name for a given code point
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
