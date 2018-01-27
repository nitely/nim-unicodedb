import math
import algorithm

proc fnv32a*(key: openarray[int], seed: uint32): uint32 =
  ## Calculates a distinct hash function for a given sequence
  ## FNV algorithm from http://isthe.com/chongo/tech/comp/fnv/
  result = 18652614'u32  # -> 2166136261 mod int32.high
  if seed > 0'u32:
    result = seed
  for s in key:
    result = result xor uint32(s)
    result = result * 16777619'u32  # unsigned will wrap around

type
  MphValueType = int or seq[int]

proc mphLookup*[T: MphValueType](
      hashes: openarray[int],
      values: openarray[T],
      key: openarray[int]
    ): T =
  assert hashes.len <= int32.high
  assert values.len <= int32.high
  let d = hashes[int(fnv32a(key, 0'u32) mod hashes.len.uint32)]
  result = values[int(fnv32a(key, d.uint32) mod values.len.uint32)]

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
    buckets[int(fnv32a(record.key, 0'u32) mod dataSize.uint32)].add(record)

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
      let slot = int(fnv32a(bucket[item].key, d.uint32) mod dataSize.uint32)
      if filled[slot] or slot in slots:
        inc d
        item = 0
        slots.setLen(0)
      else:
        inc item
        slots.add(slot)

    result.h[int(fnv32a(bucket[0].key, 0'u32) mod dataSize.uint32)] = d
    for i in 0 ..< len(bucket):
      result.v[slots[i]] = bucket[i].value
      filled[slots[i]] = true
