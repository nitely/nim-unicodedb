import strutils

const maxCP = 0x10FFFF

proc parseDBC*(filePath: string): seq[string] =
  result = newSeq[string](maxCP + 1)
  for i in 0 ..< result.len:
    result[i] = "L"
  for line in lines(filePath):
    if len(line.strip()) == 0:
      continue
    if line.startsWith("#"):
      continue

    let parts = line.split(';', 1)
    assert len(parts) == 2
    let cpRaw = parts[0].strip()
    let bi = parts[1].split('#', 1)[0].strip()

    if ".." in cpRaw:
      let
        cpRange = cpRaw.split("..")
        first = parseHexInt("0x$#" % cpRange[0])
        last = parseHexInt("0x$#" % cpRange[1])
      for cp in first .. last:
        result[cp] = bi
      continue

    result[parseHexInt("0x$#" % cpRaw)] = bi
  assert len(result) > 0
