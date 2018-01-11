import unicode

import types_data

export UnicodeTypeMask

proc unicodeTypes*(cp: int): int =
  assert cp <= 0x10FFFF
  let
    blockOffset = int(typesOffsets[cp div blockSize]) * blockSize
    idx = int(typesIndices[blockOffset + cp mod blockSize])
  result = typesData[idx]

proc unicodeTypes*(cp: Rune): int {.inline.} =
  result = unicodeTypes(int(cp))

proc contains*(ut: int, utm: UnicodeTypeMask): bool =
  result = (ut and utm.ord) != 0
