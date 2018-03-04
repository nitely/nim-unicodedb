import math
import strutils

proc prettyTable*(
    s: seq[int],
    cols: int,
    suffix = ""): string =
  ## Pretty print table. Rows are
  ## splitted by the number of ``cols``.
  ## The first item is suffixed
  ## with ``suffix``
  var
    rows = newSeq[string](int(ceil(s.len / cols)))
    row = newSeq[int](cols)
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
      rows[i] = $row[0] & suffix & ", " & join(row[1 .. ^1], ", ")
    else:
      rows[i] = join(row, ", ")
  result = join(rows, ",\L    ")
