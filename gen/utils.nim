import math
import strutils

proc prettyTable*[T: int or uint32](
  s: seq[T],
  cols: int,
  suffix = "",
  suffixAll = false
): string =
  ## Pretty print table. Rows are
  ## splitted by the number of ``cols``.
  ## The first item is suffixed
  ## with ``suffix``
  var
    rows = newSeq[string](int(ceil(s.len / cols)))
    row = newSeq[T](cols)
    sep = ","
  if suffixAll:
    sep = suffix & sep 
  for i in 0 ..< rows.len:
    for j in 0 ..< cols:
      let idx = i * cols + j
      if idx >= s.len:
        assert j > 0
        assert i == rows.len - 1
        row.setLen(j)
        break
      row[j] = s[idx]
    assert row.len > 0
    if i == 0:
      rows[i] = $row[0] & suffix & ", " & join(row[1 .. ^1], sep & " ")
    else:
      rows[i] = join(row, sep & " ")
  result = join(rows, sep & "\L    ")
