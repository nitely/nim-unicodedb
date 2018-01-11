import math
import tables

const
  maxCP = 0x10FFFF

type
  Stage2Type = int or seq[int]

  Stages*[T: Stage2Type] = tuple
    stage1: seq[int]
    stage2: seq[T]
    blockSize: int

proc makeTable*[T: Stage2Type](data: seq[T], blockSize: int): Stages[T] =
  let blocksCount = (maxCP + 1) div blockSize
  result = (
    stage1: newSeq[int](blocksCount),
    stage2: newSeqOfCap[T](len(data)),
    blockSize: blockSize)
  var stage2Lookup = initTable[seq[T], int](
    nextPowerOfTwo(blocksCount))

  for i in 0 ..< blocksCount:
    let blockOffset = i * blockSize
    var typesBlock = newSeq[T](blockSize)
    for j in 0 ..< blockSize:
      if blockOffset + j >= data.len:
        break
      typesBlock[j] = data[blockOffset + j]

    if typesBlock in stage2Lookup:
      result.stage1[i] = stage2Lookup[typesBlock]
      continue

    result.stage1[i] = len(result.stage2) div blockSize
    for t in typesBlock:
      result.stage2.add(t)
    stage2Lookup[typesBlock] = result.stage1[i]

proc findBestTable*[T: Stage2Type](data: seq[T]): Stages[T] =
  ## Generate the most compact two-stage table
  # todo: this won't always find the best table, since some times
  #       both tables may have int16.high as max size while a
  #       better table would have int8.high for one table and
  #       int16.high for the other (and yet more items when put togheter)
  result = (stage1: nil, stage2: nil, blockSize: 0)
  var best = -1
  var i = 1

  while true:
    let stagesTmp = makeTable(data, 2 ^ i)
    let total = stagesTmp.stage1.len + stagesTmp.stage2.len

    if total > best and best != -1:
      break

    best = total
    inc i
    result = stagesTmp
