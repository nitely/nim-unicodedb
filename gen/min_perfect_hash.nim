import math
import algorithm

proc fnv32a*(key: openarray[int], seed: int): int =
  ## Calculates a distinct hash function for a given sequence
  ## FNV algorithm from http://isthe.com/chongo/tech/comp/fnv/
  const fnv32Prime = 16777619
  const int32Max = int32.high

  result = 18652614  # -> 2166136261 mod int32Max
  if seed > 0:
    result = seed

  for s in key:
    result = result xor s
    result = (result * fnv32Prime) mod int32Max

type
  MphValueType = int or seq[int]

proc mphLookup*[T: MphValueType](
      hashes: openarray[int],
      values: openarray[T],
      key: openarray[int]
    ): T =
  let d = hashes[fnv32a(key, 0) mod len(hashes)]
  result = values[fnv32a(key, d) mod len(values)]

type
  Record*[T: MphValueType] = tuple
    key: seq[int]
    value: T

proc mph*[T: MphValueType](
      data: openarray[Record[T]]
    ): tuple[h: seq[int], v: seq[T]] =
  let dataSize = len(data)
  result = (
    h: newSeq[int](dataSize),
    v: newSeq[T](dataSize))
  var filled = newSeq[bool](dataSize)

  var buckets = newSeq[seq[Record[T]]](dataSize)
  for i in 0 ..< dataSize:
    buckets[i] = newSeqOfCap[Record[T]](1)

  for record in data:
    buckets[fnv32a(record.key, 0) mod dataSize].add(record)

  buckets.sort(
    proc (x, y: seq[Record[T]]): int =
      result = cmp(len(x), len(y)),
    SortOrder.Descending)

  for bucket in buckets:
    if len(bucket) == 0:
      break

    var d = 1
    var item = 0
    var slots = newSeqOfCap[int](len(bucket))

    # Try values of d until we find a hash function
    # that places all items in the bucket's free slots
    while item < len(bucket):
      let slot = fnv32a(bucket[item].key, d) mod dataSize
      if filled[slot] or slot in slots:
        inc d
        item = 0
        slots.setLen(0)
      else:
        inc item
        slots.add(slot)

    result.h[fnv32a(bucket[0].key, 0) mod dataSize] = d
    for i in 0 ..< len(bucket):
      result.v[slots[i]] = bucket[i].value
      filled[slots[i]] = true
