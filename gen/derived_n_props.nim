import strutils

const maxCP = 0x10FFFF

proc parseDNPQC*(filePath: string): seq[seq[string]] =
  result = newSeq[seq[string]](maxCP + 1)
  for line in lines(filePath):
    if len(line.strip()) == 0:
        continue
    if line.startsWith("#"):
      continue
    let parts = line.split(";")
    if len(parts) < 3:
        continue
    if parts[1].strip() notin [
        "NFC_QC",
        "NFKC_QC",
        "NFD_QC",
        "NFKD_QC"]:
      continue
    let
      cpRaw = parts[0].strip()
      qcTV = "$#_$#" % [
        parts[1].strip(),
        parts[2].split("#")[0].strip()]

    if ".." in cpRaw:
      let
        cpRange = cpRaw.split("..")
        first = parseHexInt("0x$#" % cpRange[0])
        last = parseHexInt("0x$#" % cpRange[1])
      for cp in first .. last:
        if isNil(result[cp]):
          result[cp] = newSeqOfCap[string](8)
        result[cp].add(qcTV)
      continue

    let cp = parseHexInt("0x$#" % cpRaw)
    if isNil(result[cp]):
      result[cp] = newSeqOfCap[string](8)
    result[cp].add(qcTV)

proc parseDNPExclusion*(filePath: string): seq[int] =
  result = newSeqOfCap[int](maxCP + 1)
  for line in lines(filePath):
    if len(line.strip()) == 0:
      continue
    if line.startsWith("#"):
      continue

    let parts = line.split(';', 1)
    assert len(parts) == 2
    let cpRaw = parts[0].strip()
    let tp = parts[1].split('#', 1)[0].strip()

    if tp != "Full_Composition_Exclusion":
      continue

    if ".." in cpRaw:
      let
        cpRange = cpRaw.split("..")
        first = parseHexInt("0x$#" % cpRange[0])
        last = parseHexInt("0x$#" % cpRange[1])
      for cp in first .. last:
        result.add(cp)
      continue

    result.add(parseHexInt("0x$#" % cpRaw))
  assert len(result) > 0
