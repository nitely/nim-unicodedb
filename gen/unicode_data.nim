# https://www.unicode.org/reports/tr44/tr44-24.html

import strutils

const maxCP = 0x10FFFF

proc parseUD*(filePath: string): seq[seq[string]] =
  ## Parse unicodeData.txt file and expand all CPs ranges.
  ## Format:
  ## name 0; category 1; CCC 2; bidi 3; decomp 4; num_type 5-7; 
  ## bidi_mirrored 8; old_name 9; old_note 10; uppercase 11;
  ## lowercase 12; titlecase 13
  result = newSeq[seq[string]](maxCP + 1)
  var firstCP = -1
  for line in lines(filePath):
    if len(line.strip()) == 0:
      continue

    let
      lineParts = line.split(";")
      cp = parseHexInt("0x$#" % lineParts[0])
      name = lineParts[1]

    if name.endsWith("First>"):
      assert name.startsWith("<")
      firstCP = cp
      continue

    if name.endsWith("Last>"):
      assert firstCP != -1
      assert name.startsWith("<")
      for curCP in firstCP .. cp:
        result[curCP] = lineParts[1..^1]
      continue

    result[cp] = lineParts[1..^1]

proc parseUDNames*(filePath: string): seq[string] =
  result = newSeq[string](maxCP + 1)
  for cp, record in pairs(parseUD(filePath)):
    if record.len > 0:
      result[cp] = record[0]

proc parseUDProps*(filePath: string): seq[seq[string]] =
  result = newSeq[seq[string]](maxCP + 1)
  for cp, record in pairs(parseUD(filePath)):
    if record.len > 0:
      result[cp] = @[record[1], record[2], record[3]]

proc parseUDDecomps*(filePath: string): seq[string] =
  result = newSeq[string](maxCP + 1)
  for cp, record in pairs(parseUD(filePath)):
    if record.len == 0:
      continue
    if len(record[4]) == 0:
      continue
    result[cp] = record[4]

proc parseUDCasing*(filePath: string): seq[seq[string]] =
  ## One or more fields may be empty
  result = newSeq[seq[string]](maxCP + 1)
  for cp, record in pairs(parseUD(filePath)):
    if record.len == 0:
      continue
    result[cp] = @[record[11], record[12], record[13]]
