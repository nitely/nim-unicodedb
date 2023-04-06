import strutils
import algorithm

const
  maxCP = 0x10FFFF
  bidirectionalNames* = [
    "L", "LRE", "LRO", "R", "AL", "RLE", "RLO",
    "PDF", "EN", "ES", "ET", "AN", "CS", "NSM", "BN", "B", "S", "WS",
    "ON", "LRI", "RLI", "FSI", "PDI"
  ]

# https://www.unicode.org/reports/tr44/tr44-30.html#Bidi_Class_Values
proc bdcLongToAbbr(s: string): string =
  if s in bidirectionalNames:  # already abbr
    return s
  case s:
  of "Left_To_Right":
    "L"
  of "Right_To_Left":
    "R"
  of "Arabic_Letter":
    "AL"
  of "European_Number":
    "EN"
  of "European_Separator":
    "ES"
  of "European_Terminator":
    "ET"
  of "Arabic_Number":
    "AN"
  of "Common_Separator":
    "CS"
  of "Nonspacing_Mark":
    "NSM"
  of "Boundary_Neutral":
    "BN"
  of "Paragraph_Separator":
    "B"
  of "Segment_Separator":
    "S"
  of "White_Space":
    "WS"
  of "Other_Neutral":
    "ON"
  of "Left_To_Right_Embedding":
    "LRE"
  of "Left_To_Right_Override":
    "LRO"
  of "Right_To_Left_Embedding":
    "RLE"
  of "Right_To_Left_Override":
    "RLO"
  of "Pop_Directional_Format":
    "PDF"
  of "Left_To_Right_Isolate":
    "LRI"
  of "Right_To_Left_Isolate":
    "RLI"
  of "First_Strong_Isolate":
    "FSI"
  of "Pop_Directional_Isolate":
    "PDI"
  else:
    doAssert false
    ""

proc fixMissingLine(s: string): string =
  result = s
  const missingLine = "# @missing:"
  if result.startsWith(missingLine):
    result.removePrefix(missingLine)

proc parseUDD*(
  filePath: string,
  processMissingLines = false
): seq[seq[seq[string]]] =
  ## generic parsing. Supports duplicated CPs.
  ## Parses data with format:
  ## # optional comment
  ## cp; prop1 ; propN # optional comment
  ## cp1..cp2 ; prop1 ; propN # optional comment
  result = newSeq[seq[seq[string]]](maxCP + 1)
  for rawLine in filePath.lines():
    # processing @missing lines end up with multi props, pick last one
    let line = if processMissingLines:
        rawLine.fixMissingLine
      else:
        rawLine
    if line.startsWith('#'):
      continue
    if line.strip().len == 0:
      continue
    let
      parts = line.split('#', 1)[0].split(';')
      cpRaw = parts[0].strip()
    var props = newSeq[string](parts.len - 1)
    for i in 1 .. parts.high:
      props[i - 1] = parts[i].strip()
    if ".." in cpRaw:
      let
        cpRange = cpRaw.split("..")
        first = parseHexInt("0x$#" % cpRange[0])
        last = parseHexInt("0x$#" % cpRange[1])
      for cp in first .. last:
        result[cp].add(props)
      continue
    let cp = parseHexInt("0x$#" % cpRaw)
    result[cp].add(props)

proc parseUDDNoDups*(filePath: string): seq[seq[string]] =
  ## Same as parseUDD but won't allow duplicates
  result = newSeq[seq[string]](maxCP + 1)
  for cp, props in filePath.parseUDD():
    if props.len == 0:
      continue
    doAssert props.len == 1
    result[cp] = props[0]

proc parseDBC*(filePath: string): seq[string] =
  result = newSeq[string](maxCP + 1)
  var i = 0
  for cp, props in filePath.parseUDD(processMissingLines = true):
    result[cp] = props[^1][0].bdcLongToAbbr
    inc i
  doAssert i == maxCP + 1

proc parseDNPQC*(filePath: string): seq[seq[string]] =
  result = newSeq[seq[string]](maxCP + 1)
  for cp, props in filePath.parseUDD():
    if props.len == 0:
      continue
    for p in props:
      if p.len < 2:
        continue
      if p[0] notin [
          "NFC_QC",
          "NFKC_QC",
          "NFD_QC",
          "NFKD_QC"]:
        continue
      result[cp].add("$#_$#" % [p[0], p[1]])

proc parseDNPExclusion*(filePath: string): seq[int] =
  result = newSeqOfCap[int](maxCP + 1)
  for cp, props in filePath.parseUDD():
    if props.len == 0:
      continue
    for p in props:
      if p[0] != "Full_Composition_Exclusion":
        continue
      result.add(cp)

proc parseUDDFullCaseFolding*(filePath: string): seq[seq[string]] =
  # <code>; <status>; <mapping>; # <name>
  result = newSeq[seq[string]](maxCP + 1)
  for cp, props in filePath.parseUDD():
    if props.len == 0:
      continue
    for p in props:
      if p[0] != "C" and p[0] != "F":
        continue
      assert result[cp].len == 0
      result[cp] = p

proc parseUDDEmoji*(filePath: string): seq[seq[string]] =
  result = newSeq[seq[string]](maxCP + 1)
  for cp, props in filePath.parseUDD():
    if props.len == 0:
      continue
    for p in props:
      if p[0] != "Extended_Pictographic":
        continue
      assert result[cp].len == 0
      result[cp] = p
