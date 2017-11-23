## This module provides common characters
## properties: category class, canonical
## combining class, bidirectional class and quick check (QC)

import unicode

import properties_data

export NfMasks

type
  EProps* {.pure.} = enum
    ## A type for getting a single
    ## property from the `Props` type
    CAT, CCC, BI, QC

  Props* = array[EProps, int]
    ## A type holding all common
    ## properties for a character.
    ## Use `EProps` to get one of them.
    ## It contains raw data for some of them.

proc properties*(cp: int): Props {.inline.} =
  ## Return properties for a given code point.
  ## Includes: Category, Canonical Combining Class,
  ## Bidi Class and QC. This may be used as an optimization
  ## when more than one property is required. This contains
  ## raw data for some of the properties, so one of
  ## the auxiliary procedures must be used in conjuntion.
  assert cp <= 0x10FFFF
  let
    blockOffset = int(propsOffsets[cp div blockSize]) * blockSize
    idx = propsIndices[blockOffset + cp mod blockSize]
  result = propsData[idx]

proc properties*(cp: Rune): Props {.inline.} =
  ## Return properties for a given code point.
  ## Includes: Category, Canonical Combining Class,
  ## Bidi Class and QC. This may be used as an optimization
  ## when more than one property is required. This contains
  ## raw data for some of the properties, so one of
  ## the auxiliary procedures must be used in conjuntion.
  result = properties(int(cp))

proc category*(props: Props): string {.inline.} =
  ## Return category property name for a given `Props`
  result = categoryNames[props[EProps.CAT]]

proc category*(cp: int | Rune): string {.inline.} =
  ## Return category property name for a given code point
  result = category(properties(cp))

proc bidirectional*(props: Props): string {.inline.} =
  ## Return bidirectional class name for a given `Props`
  result = bidirectionalNames[props[EProps.BI]]

proc bidirectional*(cp: int | Rune): string {.inline.} =
  ## Return bidirectional class name for a given code point
  result = bidirectional(properties(cp))

proc combining*(props: Props): int {.inline.} =
  ## Return canonical combining class property
  ## for a given `Props`
  result = props[EProps.CCC]

proc combining*(cp: int | Rune): int {.inline.} =
  ## Return canonical combining class property
  ## for a given code point
  result = combining(properties(cp))

proc quickCheck*(props: Props): int {.inline.} =
  ## Return quick check property for a given `Props`
  result = props[EProps.QC]

proc quickCheck*(cp: int | Rune): int {.inline.} =
  ## Return quick check property
  result = quickCheck(properties(cp))
