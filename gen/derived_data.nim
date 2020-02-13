import strutils
import algorithm

const maxCP = 0x10FFFF

proc parseUDD*(filePath: string): seq[seq[seq[string]]] =
  ## generic parsing. Supports duplicated CPs.
  ## Parses data with format:
  ## # optional comment
  ## cp; prop1 ; propN # optional comment
  ## cp1..cp2 ; prop1 ; propN # optional comment
  result = newSeq[seq[seq[string]]](maxCP + 1)
  for line in filePath.lines():
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
  result.fill("L")
  for cp, props in filePath.parseUDDNoDups():
    if props.len == 0:
      continue
    result[cp] = props[0]

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
