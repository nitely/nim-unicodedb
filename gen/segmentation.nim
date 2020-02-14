# https://unicode.org/reports/tr29/

import strutils

import derived_data
import two_stage_table
import utils

const
  sgwOther = 0
  sgwDoubleQuote = 1
  sgwSingleQuote = 2
  sgwHebrewLetter = 3
  sgwCr = 4
  sgwLf = 5
  sgwNewline = 6
  sgwExtend = 7
  sgwRegionalIndicator = 8
  sgwFormat = 9
  sgwKatakana = 10
  sgwAletter = 11
  sgwMidLetter = 12
  sgwMidNum = 13
  sgwMidNumLet = 14
  sgwNumeric = 15
  sgwExtendNumLet = 16
  sgwZwj = 17
  sgwWsegSpace = 18

func wordMap(s: string): int =
  result = case s:
    of "Other":
      sgwOther
    of "Double_Quote":
      sgwDoubleQuote
    of "Single_Quote":
      sgwSingleQuote
    of "Hebrew_Letter":
      sgwHebrewLetter
    of "CR":
      sgwCr
    of "LF":
      sgwLf
    of "Newline":
      sgwNewline
    of "Extend":
      sgwExtend
    of "Regional_Indicator":
      sgwRegionalIndicator
    of "Format":
      sgwFormat
    of "Katakana":
      sgwKatakana
    of "ALetter":
      sgwAletter
    of "MidLetter":
      sgwMidLetter
    of "MidNum":
      sgwMidNum
    of "MidNumLet":
      sgwMidNumLet
    of "Numeric":
      sgwNumeric
    of "ExtendNumLet":
      sgwExtendNumLet
    of "ZWJ":
      sgwZwj
    of "WSegSpace":
      sgwWsegSpace
    else:
      assert false
      -99

type
  WordProps = seq[int]

proc parseWordBreak(filePath: string): WordProps =
  let rawData = filePath.parseUDDNoDups
  result = newSeq[int](rawData.len)
  for i in 0 .. result.len-1:
    result[i] = sgwOther
  for cp, data in rawData.pairs:
    if data.len == 0:
      continue
    result[cp] = data[0].wordMap

func buildWordBreak(wordProps: WordProps): Stages[int] =
  buildTwoStageTable(wordProps)

const dataTemplate = """## This is auto-generated. Do not modify it

type
  SgWord* = distinct int8

const
  sgwOther* = $#.SgWord
  sgwDoubleQuote* = $#.SgWord
  sgwSingleQuote* = $#.SgWord
  sgwHebrewLetter* = $#.SgWord
  sgwCr* = $#.SgWord
  sgwLf* = $#.SgWord
  sgwNewline* = $#.SgWord
  sgwExtend* = $#.SgWord
  sgwRegionalIndicator* = $#.SgWord
  sgwFormat* = $#.SgWord
  sgwKatakana* = $#.SgWord
  sgwAletter* = $#.SgWord
  sgwMidLetter* = $#.SgWord
  sgwMidNum* = $#.SgWord
  sgwMidNumLet* = $#.SgWord
  sgwNumeric* = $#.SgWord
  sgwExtendNumLet* = $#.SgWord
  sgwZwj* = $#.SgWord
  sgwWsegSpace* = $#.SgWord

const
  wordBreakIndices* = [
    $#
  ]
  wordBreakData* = [
    $#
  ]
  wordBreakBlockSize* = $#
"""

when isMainModule:
  let wordProps = parseWordBreak(
    "./gen/UCD/auxiliary/WordBreakProperty.txt")
  let wordPropsTable = wordProps.buildWordBreak

  var f = open("./src/unicodedb/segmentation_data.nim", fmWrite)
  try:
    f.write(dataTemplate % [
      $sgwOther,
      $sgwDoubleQuote,
      $sgwSingleQuote,
      $sgwHebrewLetter,
      $sgwCr,
      $sgwLf,
      $sgwNewline,
      $sgwExtend,
      $sgwRegionalIndicator,
      $sgwFormat,
      $sgwKatakana,
      $sgwAletter,
      $sgwMidLetter,
      $sgwMidNum,
      $sgwMidNumLet,
      $sgwNumeric,
      $sgwExtendNumLet,
      $sgwZwj,
      $sgwWsegSpace,
      prettyTable(wordPropsTable.stage1, 15, "'i16"),
      prettyTable(wordPropsTable.stage2, 15, "'i8"),
      $wordPropsTable.blockSize
    ])
  finally:
    close(f)
