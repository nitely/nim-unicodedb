## This module provides segmentation data
## to implement text segmentation tr29

import unicode

import segmentation_data

export
  SgWord,
  sgwOther,
  sgwDoubleQuote,
  sgwSingleQuote,
  sgwHebrewLetter,
  sgwCr,
  sgwLf,
  sgwNewline,
  sgwExtend,
  sgwRegionalIndicator,
  sgwFormat,
  sgwKatakana,
  sgwAletter,
  sgwMidLetter,
  sgwMidNum,
  sgwMidNumLet,
  sgwNumeric,
  sgwExtendNumLet,
  sgwZwj,
  sgwWsegSpace

proc `==`*(a, b: SgWord): bool {.borrow.}

func wordBreakProp*(cp: Rune): SgWord {.inline.} =
  ## Return the word-break property of `cp`
  assert cp.int <= 0x10FFFF
  let blockOffset = (wordBreakIndices[cp.int div wordBreakBlockSize]).int * wordBreakBlockSize
  result = wordBreakData[blockOffset + cp.int mod wordBreakBlockSize].SgWord
