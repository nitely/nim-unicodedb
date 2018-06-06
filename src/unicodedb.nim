## This module provides support to
## access the Unicode Character Database
##
## Usage:
##
## .. code-block:: nim
##   import unicode
##   import unicodedb
##   assert category(Rune(0x860)) == "Lo"
##   assert bidirectional(Rune(0x07F7)) == "ON"
##   assert combining(Rune(0x860)) == 0
##   assert name(Rune(32)) == "SPACE"
##   assert lookupStrict("SPACE") == Rune(32)
##   assert utmUppercase in Rune(0x0041).unicodeTypes()
##   assert nfcQcNo in Rune(0x0374).quickCheck()
##
## There are more examples inluded
## within the tests module

import unicodedb/compositions
import unicodedb/decompositions
import unicodedb/properties
import unicodedb/names
import unicodedb/types

export contains
export composition
export decomposition, canonicalDecomposition
export NfMask, UnicodeProp, UnicodeProps, properties,
       category, bidirectional,
       combining, quickCheck
export name, lookupStrict
export UnicodeTypeMask, unicodeTypes

const
  unicodeVersion* = "11.0.0"
