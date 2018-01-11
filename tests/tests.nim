import unittest, strutils, unicode

import unicodedb
from unicodedb/compositions_data import compsValues
from compositions_test_data import allComps
from decompositions_test_data import allDecomps
from category_test_data import allCats
from bidi_test_data import allBidis
from combining_test_data import allCombining

const maxCP = 0x10FFFF

test "Test all compositions":
  for cps in allComps:
    check cps[0] == composition(cps[1], cps[2])

test "Test decompose-compose inception":
  var i = 0
  for cps in compsValues:
    let dcp = canonicalDecomposition(cps[2].int)
    check dcp.len == 2
    check composition(dcp[0], dcp[1]) == cps[2]
    inc i
  check i == 940

test "Test some compositions":
  check composition(123, 123) == -1
  # 0x0F9D -> 0x0F9C 0x0FB7 (but it's excluded)
  check composition(0x0F9C, 0x0FB7) == -1
  check composition(108, 803) == 7735

test "Test compositions with Runes":
  check composition(Rune(108), Rune(803)) == Rune(7735)

test "Test compositions with bad Runes":
  expect(ValueError):
    discard composition(Rune(123), Rune(123))

test "Test decompositions":
  for decomp in allDecomps:
    check decomposition(decomp.cp) == decomp.dcp

test "Test non-decompositions":
  var decomposableCps = newSeq[bool](maxCP)
  for decomp in allDecomps:
    decomposableCps[decomp.cp] = true
  for cp, isDecomposable in decomposableCps:
    if not isDecomposable:
      check decomposition(cp).len == 0

test "Test some decompositions":
  check decomposition(0x0F9D) == @[0x0F9C, 0x0FB7]
  check decomposition(190) == @[51, 8260, 52]
  check decomposition(192) == @[65, 768]
  check decomposition(123).len == 0

test "Test decompositions with Runes":
  check decomposition(Rune(0x0F9D)) == @[Rune(0x0F9C), Rune(0x0FB7)]
  check decomposition(Rune(123)).len == 0

test "Test canonical decompositions":
  for decomp in allDecomps:
    if decomp.isCanonical:
      check canonicalDecomposition(decomp.cp) == decomp.dcp

test "Test non-canonical decompositions":
  var decomposableCps = newSeq[bool](maxCP)
  for decomp in allDecomps:
    if decomp.isCanonical:
      decomposableCps[decomp.cp] = true
  for cp, isDecomposable in decomposableCps:
    if not isDecomposable:
      check canonicalDecomposition(cp).len == 0

test "Test some canonical decompositions":
  check canonicalDecomposition(192) == @[65, 768]
  check canonicalDecomposition(0x0F9D) == @[0x0F9C, 0x0FB7]
  check canonicalDecomposition(190).len == 0
  check decomposition(123).len == 0

test "Test canonical decompositions with Runes":
  check(
    canonicalDecomposition(Rune(0x0F9D)) == @[
      Rune(0x0F9C), Rune(0x0FB7)])
  check canonicalDecomposition(Rune(123)).len == 0

test "Test categories":
  var i = 0
  for cpData in allCats:
    for cp in cpData.cpFirst .. cpData.cpLast:
      # Skip unassigned since Python's DB is 9.0
      if category(cp) != cpData.cat and cpData.cat == "Cn":
        inc i
        continue
      check category(cp) == cpData.cat
  check i == 8518  # New code points in 10.0

test "Test categories with props":
  check category(properties(7913)) == "Ll"

test "Test some categories":
  # check an unassiged cp
  check category(64110) == "Cn"
  check category(7913) == "Ll"
  check category(0) == "Cc"
  check category(1048576) == "Co"
  # New in unicode 10
  check category(0x860) == "Lo"

test "Test categories with runes":
  check category(Rune(7913)) == "Ll"
  check category(properties(Rune(7913))) == "Ll"

test "Test bidirectional class":
  for cpData in allBidis:
    for cp in cpData.cpFirst .. cpData.cpLast:
      # Python's DB has empty values as default
      # (doesn't extract from derived bidi)
      if cpData.bi.len > 0:
        check bidirectional(cp) == cpData.bi

test "Test some bidirectional class":
  check bidirectional(0x860) == "AL"
  check bidirectional(0x0924) == "L"
  check bidirectional(0x1EEFF) == "AL"
  check bidirectional(0) == "BN"
  check bidirectional(0x07F7) == "ON"

test "Test some bidirectional class for runes":
  check bidirectional(Rune(0)) == "BN"
  check bidirectional(Rune(0x07F7)) == "ON"

test "Test canonical combining class":
  for cpData in allCombining:
    # Don't check non-assigned coz Python's DB is 9.0
    if not cpData.assigned:
      continue
    for cp in cpData.cpFirst .. cpData.cpLast:
      check combining(cp) == cpData.ccc

test "Test some canonical combining class":
  check combining(0x860) == 0
  check combining(0x1ABC) == 230
  check combining(0x1ABD) == 220
  check combining(0) == 0
  check combining(0x0BC8) == 0  # non-assigned
  check combining(64110) == 0  # non-assigned
  check combining(1114110) == 0  # non-assigned

test "Test some canonical combining class for runes":
  check combining(Rune(0x860)) == 0
  check combining(Rune(0x1ABC)) == 230

test "Test some quick check":
  check nfcQcNo in quickCheck(0x0374)
  check nfcQcMaybe notin quickCheck(0x0374)
  check nfcQcMaybe in quickCheck(0x115AF)
  check nfcQcNo notin quickCheck(0x115AF)
  check nfcQcMaybe in quickCheck(0x1161)
  check nfcQcNo notin quickCheck(0x1161)
  check nfcQcMaybe in quickCheck(0x1175)
  check nfcQcNo notin quickCheck(0x1175)
  check nfcQcMaybe notin quickCheck(0)
  check nfcQcNo notin quickCheck(0)

  check nfkcQcNo in quickCheck(0x00A0)
  check nfkcQcMaybe notin quickCheck(0x00A0)
  check nfkcQcMaybe in quickCheck(0x0CD6)
  check nfkcQcNo notin quickCheck(0x0CD6)
  check nfkcQcMaybe in quickCheck(0x115AF)
  check nfkcQcNo notin quickCheck(0x115AF)
  check nfkcQcNo notin quickCheck(0)
  check nfkcQcMaybe notin quickCheck(0)

  check nfdQcNo in quickCheck(0x00D6)
  check nfdQcNo in quickCheck(0x2FA1D)
  check nfdQcNo notin quickCheck(0)

  check nfkdQcNo in quickCheck(0x00D6)
  check nfkdQcNo in quickCheck(0x2FA1D)
  check nfkdQcNo notin quickCheck(0)

test "Test some quick check for runes":
  check nfcQcNo in quickCheck(Rune(0x0374))
  check nfcQcMaybe notin quickCheck(Rune(0x0374))

# There used to be a full test for names,
# but it was ~6MBs of data

test "Test some name":
  check name(32) == "SPACE"
  check name(0x12199) == "CUNEIFORM SIGN KAL CROSSING KAL"
  check name(917999) == "VARIATION SELECTOR-256"
  check name(44032) == "HANGUL SYLLABLE GA"
  check name(53728) == "HANGUL SYLLABLE TWAEL"
  check name(55203) == "HANGUL SYLLABLE HIH"
  check name(0x4E8C) == "CJK UNIFIED IDEOGRAPH-4E8C"
  check name(0x20059) == "CJK UNIFIED IDEOGRAPH-20059"
  check name(0x17000) == "TANGUT IDEOGRAPH-17000"
  check name(0x17001) == "TANGUT IDEOGRAPH-17001"
  check name(0x187EC) == "TANGUT IDEOGRAPH-187EC"
  check name(0x187ED) == ""
  check name(0x1B170) == "NUSHU CHARACTER-1B170"
  check name(0x1B171) == "NUSHU CHARACTER-1B171"
  check name(0x1B2FB) == "NUSHU CHARACTER-1B2FB"
  check name(0xF900) == "CJK COMPATIBILITY IDEOGRAPH-F900"
  check name(0xFAD9) == "CJK COMPATIBILITY IDEOGRAPH-FAD9"
  check name(0xF0000) == ""
  check name(0x10FFFD) == ""

test "Test some name for runes":
  check name(Rune(32)) == "SPACE"
  check name(Rune(0x10FFFD)) == ""

test "Test lookup names":
  for cp in 0 .. 0x10FFFF:
    let cpName = name(cp)
    if cpName.len > 0:
      check lookupStrict(cpName) == Rune(cp)

test "Test some lookup names":
  check lookupStrict("SPACE") == Rune(32)
  check lookupStrict("CUNEIFORM SIGN KAL CROSSING KAL") == Rune(0x12199)
  check lookupStrict("VARIATION SELECTOR-256") == Rune(917999)
  check lookupStrict("HANGUL SYLLABLE GA") == Rune(44032)
  check lookupStrict("HANGUL SYLLABLE TWAEL") == Rune(53728)
  check lookupStrict("HANGUL SYLLABLE HIH") == Rune(55203)
  check lookupStrict("CJK UNIFIED IDEOGRAPH-4E8C") == Rune(0x4E8C)
  check lookupStrict("CJK UNIFIED IDEOGRAPH-20059") == Rune(0x20059)
  check lookupStrict("TANGUT IDEOGRAPH-17000") == Rune(0x17000)
  check lookupStrict("TANGUT IDEOGRAPH-17001") == Rune(0x17001)
  check lookupStrict("TANGUT IDEOGRAPH-187EC") == Rune(0x187EC)
  check lookupStrict("TANGUT IDEOGRAPH-187EC") == Rune(0x187EC)
  check lookupStrict("NUSHU CHARACTER-1B170") == Rune(0x1B170)
  check lookupStrict("NUSHU CHARACTER-1B171") == Rune(0x1B171)
  check lookupStrict("NUSHU CHARACTER-1B2FB") == Rune(0x1B2FB)
  check lookupStrict("CJK COMPATIBILITY IDEOGRAPH-F900") == Rune(0xF900)
  check lookupStrict("CJK COMPATIBILITY IDEOGRAPH-FAD9") == Rune(0xFAD9)

test "Test some invalid lookup names":
  expect(KeyError):
    discard lookupStrict("")
  expect(KeyError):
    discard lookupStrict("foobar")
  expect(KeyError):
    discard lookupStrict("CJK UNIFIED IDEOGRAPH-0")
  expect(KeyError):
    discard lookupStrict("CJK UNIFIED IDEOGRAPH-foo")
  expect(KeyError):
    discard lookupStrict(
      "CJK UNIFIED IDEOGRAPH-FFFFFFFFFFFFFFFFFFFFFFFFFFFFF" &
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF" &
      "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF")
