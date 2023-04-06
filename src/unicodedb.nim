## This module provides support to
## access the Unicode Character Database
##
## Usage:
##
## .. code-block:: nim
##   import unicode
##   import unicodedb
##   assert unicodeCategory(Rune(0x860)) == ctgLo
##   assert bidirectional(Rune(0x07F7)) == "ON"
##   assert combining(Rune(0x860)) == 0
##   assert name(Rune(32)) == "SPACE"
##   assert lookupStrict("SPACE") == Rune(32)
##   assert utmUppercase in Rune(0x0041).unicodeTypes()
##   assert nfcQcNo in Rune(0x0374).quickCheck()
##
## There are more examples inluded
## within the tests module

import
  unicodedb/compositions,
  unicodedb/decompositions,
  unicodedb/properties,
  unicodedb/names,
  unicodedb/types

export
  compositions,
  decompositions,
  properties,
  names,
  types

const
  unicodeVersion* = "15.0.0"
