import math
import tables

const
  maxCP = 0x10FFFF

type
  Stage2Type = int or seq[int]

  Stages*[T: Stage2Type] = object
    ## Two-stage table
    stage1*: seq[int]
    stage2*: seq[T]
    blockSize*: int

proc makeTable*[T: Stage2Type](data: seq[T], blockSize: int): Stages[T] =
  let blocksCount = (maxCP + 1) div blockSize
  result = Stages[T](
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

proc buildTwoStageTable*(data: seq[int]): Stages[int] =
  ## ``findBestTable`` alias
  findBestTable(data)

type
  SomeData = int or seq[int]

  DataTable[T: SomeData] = object
    data: seq[T]
    offsets: seq[int]

proc buildDataTable[T](data: seq[T]): DataTable[T] =
  ## Return uncompressed table
  ## with unique data and offsets to it
  assert data.len == maxCP+1
  result = DataTable[T](
    data: newSeq[T](),
    offsets: newSeq[int](data.len))
  for cp, d in data.pairs:
    let idx = result.data.find(d)
    if idx != -1:
      result.offsets[cp] = idx
      continue
    result.offsets[cp] = result.data.len
    result.data.add(d)

type
  ThreeStageTable*[T: SomeData] = object
    stage1*: seq[int]
    stage2*: seq[int]
    stage3*: seq[T]
    blockSize*: int

proc buildThreeStageTable*[T](data: seq[T]): ThreeStageTable[T] =
  ## Build a 3-stage table.
  ## Passed data gets de-duplicated.
  ## Use ``findBestTable`` to get a 2-stage table
  let
    dataTable = buildDataTable(data)
    stages = findBestTable(dataTable.offsets)
  assert stages.blockSize > 0
  result = ThreeStageTable[T](
    stage1: stages.stage1,
    stage2: stages.stage2,
    stage3: dataTable.data,
    blockSize: stages.blockSize)
