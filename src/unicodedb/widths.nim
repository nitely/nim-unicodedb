## This module implements
## East Asian Width - tr11 (http://www.unicode.org/reports/tr11/)

import unicode

import widths_data

export UnicodeWidth

proc widthMap(w: int): UnicodeWidth =
  case w:
  of uwdtAmbiguous.ord:
    uwdtAmbiguous
  of uwdtFull.ord:
    uwdtFull
  of uwdtHalf.ord:
    uwdtHalf
  of uwdtNarrow.ord:
    uwdtNarrow
  of uwdtWide.ord:
    uwdtWide
  of uwdtNeutral.ord:
    uwdtNeutral
  else:
    assert false
    uwdtNeutral

proc unicodeWidth*(r: Rune): UnicodeWidth =
  ## Return width for a given rune
  assert r.int <= 0x10FFFF
  let
    blockOffset = (widthsOffsets[r.int div blockSize]).int * blockSize
    idx = widthsIndices[blockOffset + r.int mod blockSize]
  result = widthsData[idx].widthMap
