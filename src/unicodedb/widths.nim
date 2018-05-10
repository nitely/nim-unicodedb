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
  ## Return width for a given rune.
  ## Return value is one of: ``uwdtAmbiguous``,
  ## ``uwdtFull``, ``uwdtHalf``, ``uwdtNarrow``,
  ## ``uwdtWide`` and ``uwdtNeutral``
  assert r.int <= 0x10FFFF
  let blockOffset = (widthsIndices[r.int div blockSize]).int * blockSize
  result = widthsData[blockOffset + r.int mod blockSize].widthMap
