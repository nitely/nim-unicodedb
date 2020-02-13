# Resources:
# http://www.unicode.org/versions/Unicode12.1.0/ch03.pdf
# 3.13  Default Case Algorithms
# http://www.unicode.org/versions/Unicode12.1.0/ch04.pdf#M9.27678.Heading.41.Case
# http://www.unicode.org/versions/Unicode12.1.0/ch05.pdf#G21180
# https://unicode.org/faq/casemap_charprop.html

import strutils

import unicode_data
import derived_data
import two_stage_table
import utils

type
  Mapping = seq[int]
  Casing = object
    uppercase: Mapping
    lowercase: Mapping
    titlecase: Mapping

func parseSimpleCasing(rawData: seq[seq[string]]): seq[Casing] =
  result = newSeq[Casing](rawData.len)
  for cp, data in rawData.pairs:
    if data.len == 0:
      continue
    if data[0].len > 0:
      result[cp].uppercase.add(parseHexInt("0x$#" % data[0]))
    if data[1].len > 0:
      result[cp].lowercase.add(parseHexInt("0x$#" % data[1]))
    if data[2].len > 0:
      result[cp].titlecase.add(parseHexInt("0x$#" % data[2]))
    # titlecase = uppercase if empty (simple mapping only, see tr44)
    if result[cp].titlecase.len == 0:
      result[cp].titlecase = result[cp].uppercase

proc parseSimpleCasing(filePath: string): seq[Casing] =
  filePath
    .parseUDCasing
    .parseSimpleCasing

proc parseSpecialCasing(filePath: string): seq[Casing] =
  # lower; title; upper; conditional?
  let rawData = filePath.parseUDD
  result = newSeq[Casing](rawData.len)
  var i = 0
  for cp, props in rawData.pairs:
    if props.len == 0:
      continue
    i = 0
    for p in props:
      if p.len > 4:  # conditional mapping
        continue
      assert p[3].strip.len == 0  # comment
      for pp in 0 .. 2:
        let casing = p[pp].split(' ')
        let c0 = parseHexInt("0x$#" % casing[0])
        if casing.len == 1 and cp == c0:
          continue
        for ca in casing:
          assert ca.strip.len > 0
          let caCp = parseHexInt("0x$#" % ca)
          if pp == 0:
            result[cp].lowercase.add(caCp)
          elif pp == 1:
            result[cp].titlecase.add(caCp)
          elif pp == 2:
            result[cp].uppercase.add(caCp)
          else:
            assert false
      inc i
    doAssert i <= 1

func mergeCasings(simple, special: seq[Casing]): seq[Casing] =
  ## overwrite simple casing by special casing
  result = simple
  for cp in 0 .. special.len-1:
    if special[cp].uppercase.len > 0:
      result[cp].uppercase = special[cp].uppercase
    if special[cp].lowercase.len > 0:
      result[cp].lowercase = special[cp].lowercase
    if special[cp].titlecase.len > 0:
      result[cp].titlecase = special[cp].titlecase

proc parse(simple, special: string): seq[Casing] =
  let simpleCasings = simple.parseSimpleCasing
  let specialCasings = special.parseSpecialCasing
  result = mergeCasings(simpleCasings, specialCasings)

type
  Folding = seq[int]

proc parseFolding(filePath: string): seq[Folding] =
  let rawData = filePath.parseUDDFullCaseFolding
  result = newSeq[Folding](rawData.len)
  for cp, props in rawData.pairs:
    if props.len == 0:
      continue
    for c in props[1].strip.split(' '):
      result[cp].add parseHexInt("0x$#" % c)

type
  CasingTable = object
    cps: seq[int]
    offsets: seq[int]

# Build table of values with dynamic len
func buildCasingTable(casings: seq[Mapping]): CasingTable =
  var cpsSize = 0
  for ca in casings:
    if ca.len > 0:
      cpsSize += len(ca) + 1  # + len

  result = CasingTable(
    cps: newSeq[int](cpsSize),
    offsets: newSeq[int](len(casings)))
  for i in 0 ..< len(casings):
    result.offsets[i] = -1
  
  var offset = 0
  for cp, ca in casings.pairs:
    if ca.len == 0:
      continue
    result.offsets[cp] = offset
    result.cps[offset] = ca.len
    inc offset
    for cp2 in ca:
      result.cps[offset] = cp2
      inc offset
  assert offset == result.cps.len

type
  MultiStageTable = object
    data: seq[int]
    stage1: seq[int]
    stage2: seq[int]
    blockSize: int

func buildMultiStageTable(casingTable: CasingTable): MultiStageTable =
  let stageTable = findBestTable(casingTable.offsets)
  assert stageTable.blockSize > 0
  result = MultiStageTable(
    data: casingTable.cps,
    stage1: stageTable.stage1,
    stage2: stageTable.stage2,
    blockSize: stageTable.blockSize)

proc buildUpperCase(casings: seq[Casing]): MultiStageTable =
  var uppercase = newSeq[Mapping](casings.len)
  for i in 0 .. casings.len-1:
    uppercase[i] = casings[i].uppercase
  result = uppercase
    .buildCasingTable
    .buildMultiStageTable

func buildTitleCase(casings: seq[Casing]): MultiStageTable =
  var titlecase = newSeq[Mapping](casings.len)
  for i in 0 .. casings.len-1:
    titlecase[i] = casings[i].titlecase
  result = titlecase
    .buildCasingTable
    .buildMultiStageTable

func buildLowerCase(casings: seq[Casing]): MultiStageTable =
  var lowercase = newSeq[Mapping](casings.len)
  for i in 0 .. casings.len-1:
    lowercase[i] = casings[i].lowercase
  result = lowercase
    .buildCasingTable
    .buildMultiStageTable

func buildCaseFolding(foldings: seq[Folding]): MultiStageTable =
  result = foldings
    .buildCasingTable
    .buildMultiStageTable

#[
func buildLowerCase(casings: seq[Casing]): Stages[int] =
  var data = newSeq[int](casings.len)
  for i in 0 .. data.len-1:
    data[i] = -1
  for cp, ca in casings.pairs:
    assert ca.lowercase.len <= 1
    if ca.lowercase.len == 1:
      assert data[cp] != ca.lowercase[0]
      data[cp] = ca.lowercase[0]
  result = buildTwoStageTable(data)
]#

const dataTemplate = """## This is auto-generated. Do not modify it

const
  lowercaseOffsets* = [
    $#
  ]
  lowercaseIndices* = [
    $#
  ]
  lowercaseData* = [
    $#
  ]
  lowercaseBlockSize* = $#

  uppercaseOffsets* = [
    $#
  ]
  uppercaseIndices* = [
    $#
  ]
  uppercaseData* = [
    $#
  ]
  uppercaseBlockSize* = $#

  titlecaseOffsets* = [
    $#
  ]
  titlecaseIndices* = [
    $#
  ]
  titlecaseData* = [
    $#
  ]
  titlecaseBlockSize* = $#

  casefoldOffsets* = [
    $#
  ]
  casefoldIndices* = [
    $#
  ]
  casefoldData* = [
    $#
  ]
  casefoldBlockSize* = $#
"""

when isMainModule:
  let casings = parse(
    "./gen/UCD/UnicodeData.txt",
    "./gen/UCD/SpecialCasing.txt")
  let lowerTable = casings.buildLowerCase
  let upperTable = casings.buildUpperCase
  let titleTable = casings.buildTitleCase

  let foldings = parseFolding("./gen/UCD/CaseFolding.txt")
  let foldingTable = foldings.buildCaseFolding

  var f = open("./src/unicodedb/casing_data.nim", fmWrite)
  try:
    f.write(dataTemplate % [
      prettyTable(lowerTable.stage1, 15, "'i8"),
      prettyTable(lowerTable.stage2, 15, "'i16"),
      prettyTable(lowerTable.data, 15, "'i32"),
      $lowerTable.blockSize,
      prettyTable(upperTable.stage1, 15, "'i8"),
      prettyTable(upperTable.stage2, 15, "'i16"),
      prettyTable(upperTable.data, 15, "'i32"),
      $upperTable.blockSize,
      prettyTable(titleTable.stage1, 15, "'i8"),
      prettyTable(titleTable.stage2, 15, "'i16"),
      prettyTable(titleTable.data, 15, "'i32"),
      $titleTable.blockSize,
      prettyTable(foldingTable.stage1, 15, "'i8"),
      prettyTable(foldingTable.stage2, 15, "'i16"),
      prettyTable(foldingTable.data, 15, "'i32"),
      $foldingTable.blockSize
    ])
  finally:
    close(f)
