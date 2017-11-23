## This module provides support to
## access the Unicode Character Database
##
## Usage:
##
## .. code-block:: nim
##   import unicode
##   import unicodedb
##   echo category(Rune(0x860)) == "Lo"
##   echo bidirectional(Rune(0x07F7)) == "ON"
##   echo combining(Rune(0x860)) == 0
##   echo name(Rune(32)) == "SPACE"
##   echo lookupStrict("SPACE") == Rune(32)
##
## There are more examples inluded
## within the tests module

import unicodedb/compositions
import unicodedb/decompositions
import unicodedb/properties
import unicodedb/names

export composition
export decomposition, canonicalDecomposition
export NfMasks, EProps, Props, properties,
       category, bidirectional,
       combining, quickCheck
export name, lookupStrict

const
  unicodeVersion* = "10.0.0"
