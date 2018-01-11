## This module provides common characters
## properties: category class, canonical
## combining class, bidirectional class and quick check (QC)

import unicode

import properties_data

export NfMask

type
  Prop* = enum
    ## A type for getting a single
    ## property from the `Props` type
    propCat  # Category
    propCcc  # Combining class
    propBi  # Bidirectional
    propQc  # QuikCheck
    propFl  # Flags (NumericType, ...)

  Props* = array[Prop, int]
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
  result = categoryNames[props[propCat]]

proc category*(cp: int | Rune): string {.inline.} =
  ## Return category property name for a given code point
  result = category(properties(cp))

proc bidirectional*(props: Props): string {.inline.} =
  ## Return bidirectional class name for a given `Props`
  result = bidirectionalNames[props[propBi]]

proc bidirectional*(cp: int | Rune): string {.inline.} =
  ## Return bidirectional class name for a given code point
  result = bidirectional(properties(cp))

proc combining*(props: Props): int {.inline.} =
  ## Return canonical combining class property
  ## for a given `Props`
  result = props[propCcc]

proc combining*(cp: int | Rune): int {.inline.} =
  ## Return canonical combining class property
  ## for a given code point
  result = combining(properties(cp))

proc contains*(qc: int, m: NfMask): bool =
  result = (qc and m.ord) != 0

proc quickCheck*(props: Props): int {.inline.} =
  ## Return quick check property for a given `Props`
  result = props[propQc]

proc quickCheck*(cp: int | Rune): int {.inline.} =
  ## Return quick check property
  result = quickCheck(properties(cp))
