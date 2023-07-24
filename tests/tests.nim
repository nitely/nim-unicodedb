import unittest
import unicode
import sequtils

import unicodedb
import unicodedb/widths
import unicodedb/scripts
import unicodedb/casing
import unicodedb/segmentation
import unicodedb/collation
from unicodedb/compositions_data import compsValues
from compositions_test_data import allComps
from decompositions_test_data import allDecomps
from category_test_data import allCats
from bidi_test_data import allBidis
from combining_test_data import allCombining
from types_test_data import allTypes
import casing_test_data
import word_break_test_data

const maxCp = 0x10FFFF

proc toRunes(runes: seq[int]): seq[Rune] =
  result = @[]
  for cp in runes:
    result.add(cp.Rune)

test "Test all compositions":
  for cps in allComps:
    check cps[0].Rune == composition(cps[1].Rune, cps[2].Rune)

test "Test decompose-compose inception":
  var i = 0
  for cps in compsValues:
    let dcp = canonicalDecomposition(cps[2].Rune)
    check dcp.len == 2
    check composition(dcp[0], dcp[1]) == cps[2].Rune
    inc i
  check i == 941

test "Test some compositions":
  block:
    var r: Rune
    check(not composition(r, 123.Rune, 123.Rune))
  # 0x0F9D -> 0x0F9C 0x0FB7 (but it's excluded)
  expect(ValueError):
    discard composition(0x0F9C.Rune, 0x0FB7.Rune)
  check composition(108.Rune, 803.Rune) == 7735.Rune

test "Test decompositions":
  for decomp in allDecomps:
    check decomposition(decomp.cp.Rune) == decomp.dcp.toRunes

test "Test non-decompositions":
  var decomposableCps = newSeq[bool](maxCp)
  for decomp in allDecomps:
    decomposableCps[decomp.cp] = true
  var i = 0
  for cp, isDecomposable in decomposableCps:
    if not isDecomposable and decomposition(cp.Rune).len > 0:
      #echo cp.Rune.int
      inc i
  check i == 62  # new decomposite CPs

test "Test some decompositions":
  check decomposition(0x0F9D.Rune) == @[0x0F9C.Rune, 0x0FB7.Rune]
  check decomposition(190.Rune) == @[51.Rune, 8260.Rune, 52.Rune]
  check decomposition(192.Rune) == @[65.Rune, 768.Rune]
  check decomposition(123.Rune).len == 0
  # unicode 12
  check decomposition(0x32FF.Rune) == @[0x4EE4.Rune, 0x548C.Rune]
  check decomposition(0x1F16C.Rune) == @[0x004D.Rune, 0x0052.Rune]

test "Test canonical decompositions":
  for decomp in allDecomps:
    if decomp.isCanonical:
      check canonicalDecomposition(decomp.cp.Rune) == decomp.dcp.toRunes

test "Test non-canonical decompositions":
  var decomposableCps = newSeq[bool](maxCp)
  for decomp in allDecomps:
    if decomp.isCanonical:
      decomposableCps[decomp.cp] = true
  for cp, isDecomposable in decomposableCps:
    if not isDecomposable:
      check canonicalDecomposition(cp.Rune).len == 0

test "Test some canonical decompositions":
  check canonicalDecomposition(192.Rune) == @[65.Rune, 768.Rune]
  check canonicalDecomposition(0x0F9D.Rune) == @[0x0F9C.Rune, 0x0FB7.Rune]
  check canonicalDecomposition(190.Rune).len == 0
  check decomposition(123.Rune).len == 0

test "Test categories":
  var i = 0
  for cpData in allCats:
    for cp in cpData.cpFirst .. cpData.cpLast:
      # Skip unassigned since test data has previous UCD version
      if (unicodeCategory(cp.Rune) != cpData.cat.UnicodeCategory and
          cpData.cat.UnicodeCategory == ctgCn):
        inc i
        continue
      if (unicodeCategory(cp.Rune) != cpData.cat.UnicodeCategory):
        echo $cp
        echo $unicodeCategory(cp.Rune).int
      check unicodeCategory(cp.Rune) == cpData.cat.UnicodeCategory
  check i == 4489  # New code points

test "Test categories with props":
  check unicodeCategory(properties(7913.Rune)) == ctgLl

test "Test some categories":
  # check an unassiged cp
  check unicodeCategory(64110.Rune) == ctgCn
  check unicodeCategory(7913.Rune) == ctgLl
  check unicodeCategory(0.Rune) == ctgCc
  check unicodeCategory(1048576.Rune) == ctgCo
  # New in unicode 10
  check unicodeCategory(0x860.Rune) == ctgLo
  # New in unicode 11
  check unicodeCategory(70089.Rune) == ctgMn
  check unicodeCategory(72199.Rune) == ctgMn
  check unicodeCategory(72200.Rune) == ctgMn
  # New in unicode 12
  check unicodeCategory(0x166D.Rune) == ctgSo
  check unicodeCategory(0x1CF2.Rune) == ctgLo
  check unicodeCategory(0xA9BD.Rune) == ctgMn
  # New in unicode 13
  check unicodeCategory(0x1FBF9.Rune) == ctgNd
  check unicodeCategory(0x1FBB2.Rune) == ctgSo

test "Test some categories at CT":
  static:
    doAssert unicodeCategory(64110.Rune) == ctgCn
    doAssert unicodeCategory(7913.Rune) == ctgLl
    doAssert unicodeCategory(0.Rune) == ctgCc
    doAssert unicodeCategory(1048576.Rune) == ctgCo
    doAssert unicodeCategory(0x860.Rune) == ctgLo
    doAssert unicodeCategory(70089.Rune) == ctgMn
    doAssert unicodeCategory(72199.Rune) == ctgMn
    doAssert unicodeCategory(72200.Rune) == ctgMn
    doAssert unicodeCategory(0x166D.Rune) == ctgSo
    doAssert unicodeCategory(0x1CF2.Rune) == ctgLo
    doAssert unicodeCategory(0xA9BD.Rune) == ctgMn

test "Test bidirectional class":
  for cpData in allBidis:
    for cp in cpData.cpFirst .. cpData.cpLast:
      if bidirectional(cp.Rune) != cpData.bi and not cpData.assigned:
        continue
      if (bidirectional(cp.Rune) != cpData.bi):
        echo $cp
        echo bidirectional(cp.Rune)
      check bidirectional(cp.Rune) == cpData.bi

test "Test some bidirectional class":
  check bidirectional(0x860.Rune) == "AL"
  check bidirectional(0x0924.Rune) == "L"
  check bidirectional(0x1EEFF.Rune) == "AL"
  check bidirectional(0.Rune) == "BN"
  check bidirectional(0x07F7.Rune) == "ON"
  # New in Unicode 11
  check bidirectional(0x111c9.Rune) == "NSM"
  check bidirectional(0x111CC.Rune) == "NSM"
  check bidirectional(0x1133B.Rune) == "NSM"
  check bidirectional(0x1133C.Rune) == "NSM"

test "Test canonical combining class":
  var i = 0
  for cpData in allCombining:
    for cp in cpData.cpFirst .. cpData.cpLast:
      if cpData.assigned:
        check combining(cp.Rune) == cpData.ccc
      elif combining(cp.Rune) != cpData.ccc:
        inc i
  check i == 10

test "Test some canonical combining class":
  check combining(0x860.Rune) == 0
  check combining(0x1ABC.Rune) == 230
  check combining(0x1ABD.Rune) == 220
  check combining(0.Rune) == 0
  check combining(0x0BC8.Rune) == 0  # non-assigned
  check combining(64110.Rune) == 0  # non-assigned
  check combining(1114110.Rune) == 0  # non-assigned
  # unicode 12
  check combining(0xEBA.Rune) == 9
  check combining(0x1E2EC.Rune) == 230
  check combining(0x1E2EF.Rune) == 230
  # unicode 13
  check combining(0x1F90C.Rune) == 0

test "Test some quick check":
  check nfcQcNo in quickCheck(0x0374.Rune)
  check nfcQcMaybe notin quickCheck(0x0374.Rune)
  check nfcQcMaybe in quickCheck(0x115AF.Rune)
  check nfcQcNo notin quickCheck(0x115AF.Rune)
  check nfcQcMaybe in quickCheck(0x1161.Rune)
  check nfcQcNo notin quickCheck(0x1161.Rune)
  check nfcQcMaybe in quickCheck(0x1175.Rune)
  check nfcQcNo notin quickCheck(0x1175.Rune)
  check nfcQcMaybe notin quickCheck(0.Rune)
  check nfcQcNo notin quickCheck(0.Rune)

  check nfkcQcNo in quickCheck(0x00A0.Rune)
  check nfkcQcMaybe notin quickCheck(0x00A0.Rune)
  check nfkcQcMaybe in quickCheck(0x0CD6.Rune)
  check nfkcQcNo notin quickCheck(0x0CD6.Rune)
  check nfkcQcMaybe in quickCheck(0x115AF.Rune)
  check nfkcQcNo notin quickCheck(0x115AF.Rune)
  check nfkcQcNo notin quickCheck(0.Rune)
  check nfkcQcMaybe notin quickCheck(0.Rune)

  check nfdQcNo in quickCheck(0x00D6.Rune)
  check nfdQcNo in quickCheck(0x2FA1D.Rune)
  check nfdQcNo notin quickCheck(0.Rune)

  check nfkdQcNo in quickCheck(0x00D6.Rune)
  check nfkdQcNo in quickCheck(0x2FA1D.Rune)
  check nfkdQcNo notin quickCheck(0.Rune)

# There used to be a full test for names,
# but it was ~6MBs of data

test "Test some name":
  check name(32.Rune) == "SPACE"
  check name(0x12199.Rune) == "CUNEIFORM SIGN KAL CROSSING KAL"
  check name(917999.Rune) == "VARIATION SELECTOR-256"
  check name(44032.Rune) == "HANGUL SYLLABLE GA"
  check name(53728.Rune) == "HANGUL SYLLABLE TWAEL"
  check name(55203.Rune) == "HANGUL SYLLABLE HIH"
  check name(0x4E8C.Rune) == "CJK UNIFIED IDEOGRAPH-4E8C"
  check name(0x20059.Rune) == "CJK UNIFIED IDEOGRAPH-20059"
  check name(0x17000.Rune) == "TANGUT IDEOGRAPH-17000"
  check name(0x17001.Rune) == "TANGUT IDEOGRAPH-17001"
  check name(0x187EC.Rune) == "TANGUT IDEOGRAPH-187EC"
  check name(0x187ED.Rune) == "TANGUT IDEOGRAPH-187ED"  # Unicode 13
  check name(0x1B170.Rune) == "NUSHU CHARACTER-1B170"
  check name(0x1B171.Rune) == "NUSHU CHARACTER-1B171"
  check name(0x1B2FB.Rune) == "NUSHU CHARACTER-1B2FB"
  check name(0xF900.Rune) == "CJK COMPATIBILITY IDEOGRAPH-F900"
  check name(0xFAD9.Rune) == "CJK COMPATIBILITY IDEOGRAPH-FAD9"
  check name(0xF0000.Rune) == ""
  check name(0x10FFFD.Rune) == ""

test "Test lookup names":
  for cp in 0 .. 0x10FFFF:
    let cpName = name(cp.Rune)
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

test "Test types":
  var i = 0
  for cpData in allTypes:
    for cp in cpData.first .. cpData.last:
      # Skip unassigned
      if unicodeCategory(cp.Rune) != ctgCn and not cpData.asig:
        inc i
        continue
      check(utmDecimal in unicodeTypes(cp.Rune) == cpData.de)
      check(utmDigit in unicodeTypes(cp.Rune) == cpData.di)
      check(utmNumeric in unicodeTypes(cp.Rune) == cpData.nu)
      if cp in [4348, 42994, 42995, 42996, 43881]:  # unicode 15 skip
        continue
      check(utmLowercase in unicodeTypes(cp.Rune) == cpData.lo)
      check(utmUppercase in unicodeTypes(cp.Rune) == cpData.up)
  check i == 4489  # new codepoints

test "Test some types":
  check utmDecimal in unicodeTypes(Rune(0x0030))
  check utmDecimal in unicodeTypes(Rune(0x0039))
  check utmDecimal in unicodeTypes(Rune(0x1E959))
  check utmDecimal notin unicodeTypes(Rune(0x2CFD))

  check utmDigit in unicodeTypes(Rune(0x00B2))
  check utmDigit in unicodeTypes(Rune(0x1F10A))
  check utmDigit notin unicodeTypes(Rune(0x0030))
  check utmDigit notin unicodeTypes(Rune(0x3007))

  check utmNumeric in unicodeTypes(Rune(0x2CFD))
  check utmNumeric in unicodeTypes(Rune(0x3007))
  check utmNumeric notin unicodeTypes(Rune(0x0030))

  check utmLowercase in unicodeTypes(Rune(0x1E69))
  check utmLowercase in unicodeTypes(Rune(0x2C74))
  check utmLowercase notin unicodeTypes(Rune('$'.ord))
  check utmLowercase notin unicodeTypes(0x0041.Rune)

  check utmUppercase in unicodeTypes(Rune(0x0041))
  check utmUppercase in unicodeTypes(Rune(0x005A))
  check utmUppercase in unicodeTypes(Rune(0x1F189))
  check utmUppercase notin unicodeTypes(Rune('$'.ord))
  check utmUppercase notin unicodeTypes(Rune(0x1E69))

  check utmCased in unicodeTypes(Rune(0x0041))
  check utmCased in unicodeTypes(Rune(0x005A))
  check utmCased in unicodeTypes(Rune(0x1F189))
  check utmCased in unicodeTypes(Rune(0x1E69))
  check utmCased notin unicodeTypes(Rune('$'.ord))

  check utmWhiteSpace in unicodeTypes(Rune(0x0009))
  check utmWhiteSpace in unicodeTypes(Rune(0x000D))
  check utmWhiteSpace in unicodeTypes(Rune(0x3000))
  check utmWhiteSpace notin unicodeTypes(Rune('$'.ord))

  check(utmLowercase in unicodeTypes(Rune(0x10D0)))

  check utmDecimal + utmWhiteSpace in 0x0030.Rune.unicodeTypes
  check utmDecimal + utmWhiteSpace in 0x0009.Rune.unicodeTypes
  check utmUppercase + utmLowercase in 0x0041.Rune.unicodeTypes
  check utmUppercase + utmLowercase in 0x1E69.Rune.unicodeTypes
  check utmUppercase + utmLowercase notin 0x0030.Rune.unicodeTypes
  block:
    const typ = utmDecimal + utmUppercase + utmLowercase + utmWhiteSpace
    check typ in 0x0030.Rune.unicodeTypes
    check typ in 0x0009.Rune.unicodeTypes
    check typ in 0x0041.Rune.unicodeTypes
    check typ in 0x1E69.Rune.unicodeTypes

test "Test some types at CT":
  static:
    doAssert utmDecimal in unicodeTypes(Rune(0x0030))
    doAssert utmDecimal in unicodeTypes(Rune(0x0039))
    doAssert utmDecimal in unicodeTypes(Rune(0x1E959))
    doAssert utmDecimal notin unicodeTypes(Rune(0x2CFD))

test "Test WhiteSpace":
  let expected = {
    0x0009'i16 .. 0x000D, 0x0020, 0x0085, 0x00A0,
    0x1680, 0x2000 .. 0x200A, 0x2028, 0x2029,
    0x202F, 0x205F, 0x3000}
  for cp in 0 .. 0x10FFFF:
    if utmWhiteSpace in unicodeTypes(cp.Rune):
      check cp.int16 in expected
    if cp <= int16.high and cp.int16 in expected:
      check utmWhiteSpace in unicodeTypes(cp.Rune)

test "Test Word":
  for cp in 0 .. 0x10FFFF:
    if utmWord in unicodeTypes(cp.Rune):
      check(
        unicodeCategory(cp.Rune) in ctgPc+ctgMn+ctgMc+ctgMe or
        utmDecimal in unicodeTypes(cp.Rune) or
        # alphanumeric
        utmLowercase in unicodeTypes(cp.Rune) or
        utmUppercase in unicodeTypes(cp.Rune) or
        unicodeCategory(cp.Rune) in ctgLt+ctgLm+ctgLo+ctgNl or
        unicodeCategory(cp.Rune) in ctgMn+ctgMc+ctgSo or
        # Join_Control
        cp in 0x200C .. 0x200D)
    # No idea how to derive Other_Alphanumeric,
    # but this is good enough
    if (unicodeCategory(cp.Rune) in ctgPc+ctgMn+ctgMc+ctgMe or
        utmDecimal in unicodeTypes(cp.Rune) or
        # alphanumeric
        utmLowercase in unicodeTypes(cp.Rune) or
        utmUppercase in unicodeTypes(cp.Rune) or
        unicodeCategory(cp.Rune) in ctgLt+ctgLm+ctgLo+ctgNl or
        #category(cp) in ["Mn", "Mc", "So"] or
        # Join_Control
        cp in 0x200C .. 0x200D):
      check utmWord in unicodeTypes(cp.Rune)

test "Test Width":
  for c in 'a' .. 'z':
    check c.ord.Rune.unicodeWidth == uwdtNarrow
  for c in 'A' .. 'Z':
    check c.ord.Rune.unicodeWidth == uwdtNarrow
  for c in '0' .. '9':
    check c.ord.Rune.unicodeWidth == uwdtNarrow
  for c in 0x0000 .. 0x001F:
    check c.Rune.unicodeWidth == uwdtNeutral
  check 0x10FFFD.Rune.unicodeWidth == uwdtAmbiguous
  check 0x3400.Rune.unicodeWidth == uwdtWide
  check 0x20000.Rune.unicodeWidth == uwdtWide
  check 0x2FA1D.Rune.unicodeWidth == uwdtWide
  check 0x20A9.Rune.unicodeWidth == uwdtHalf
  check 0x3000.Rune.unicodeWidth == uwdtFull
  check 0x10FFFF.Rune.unicodeWidth == uwdtNeutral
  check 0x0DC7.Rune.unicodeWidth == uwdtNeutral
  check 0x11358.Rune.unicodeWidth == uwdtNeutral
  check "🕺".runeAt(0).unicodeWidth == uwdtWide
  check "🇦".runeAt(0).unicodeWidth == uwdtNeutral

test "Test Script":
  check Rune(0).unicodeScript == sptCommon
  check Rune(65).unicodeScript == sptLatin
  check Rune(746).unicodeScript == sptBopomofo
  check Rune(768).unicodeScript == sptInherited
  check Rune(880).unicodeScript == sptGreek
  check Rune(994).unicodeScript == sptCoptic
  check Rune(1024).unicodeScript == sptCyrillic
  check Rune(1329).unicodeScript == sptArmenian
  check Rune(1425).unicodeScript == sptHebrew
  check Rune(1536).unicodeScript == sptArabic
  check Rune(1792).unicodeScript == sptSyriac
  check Rune(1920).unicodeScript == sptThaana
  check Rune(1984).unicodeScript == sptNko
  check Rune(2048).unicodeScript == sptSamaritan
  check Rune(2112).unicodeScript == sptMandaic
  check Rune(2304).unicodeScript == sptDevanagari
  check Rune(2432).unicodeScript == sptBengali
  check Rune(2561).unicodeScript == sptGurmukhi
  check Rune(2689).unicodeScript == sptGujarati
  check Rune(2817).unicodeScript == sptOriya
  check Rune(2946).unicodeScript == sptTamil
  check Rune(3072).unicodeScript == sptTelugu
  check Rune(3200).unicodeScript == sptKannada
  check Rune(3328).unicodeScript == sptMalayalam
  check Rune(3458).unicodeScript == sptSinhala
  check Rune(3585).unicodeScript == sptThai
  check Rune(3713).unicodeScript == sptLao
  check Rune(3840).unicodeScript == sptTibetan
  check Rune(4096).unicodeScript == sptMyanmar
  check Rune(4256).unicodeScript == sptGeorgian
  check Rune(4352).unicodeScript == sptHangul
  check Rune(4608).unicodeScript == sptEthiopic
  check Rune(5024).unicodeScript == sptCherokee
  check Rune(5120).unicodeScript == sptCanadianAboriginal
  check Rune(5760).unicodeScript == sptOgham
  check Rune(5792).unicodeScript == sptRunic
  check Rune(5888).unicodeScript == sptTagalog
  check Rune(5920).unicodeScript == sptHanunoo
  check Rune(5952).unicodeScript == sptBuhid
  check Rune(5984).unicodeScript == sptTagbanwa
  check Rune(6016).unicodeScript == sptKhmer
  check Rune(6144).unicodeScript == sptMongolian
  check Rune(6400).unicodeScript == sptLimbu
  check Rune(6480).unicodeScript == sptTaiLe
  check Rune(6528).unicodeScript == sptNewTaiLue
  check Rune(6656).unicodeScript == sptBuginese
  check Rune(6688).unicodeScript == sptTaiTham
  check Rune(6912).unicodeScript == sptBalinese
  check Rune(7040).unicodeScript == sptSundanese
  check Rune(7104).unicodeScript == sptBatak
  check Rune(7168).unicodeScript == sptLepcha
  check Rune(7248).unicodeScript == sptOlChiki
  check Rune(10240).unicodeScript == sptBraille
  check Rune(11264).unicodeScript == sptGlagolitic
  check Rune(11568).unicodeScript == sptTifinagh
  check Rune(11904).unicodeScript == sptHan
  check Rune(12353).unicodeScript == sptHiragana
  check Rune(12449).unicodeScript == sptKatakana
  check Rune(40960).unicodeScript == sptYi
  check Rune(42192).unicodeScript == sptLisu
  check Rune(42240).unicodeScript == sptVai
  check Rune(42656).unicodeScript == sptBamum
  check Rune(43008).unicodeScript == sptSylotiNagri
  check Rune(43072).unicodeScript == sptPhagsPa
  check Rune(43136).unicodeScript == sptSaurashtra
  check Rune(43264).unicodeScript == sptKayahLi
  check Rune(43312).unicodeScript == sptRejang
  check Rune(43392).unicodeScript == sptJavanese
  check Rune(43520).unicodeScript == sptCham
  check Rune(43648).unicodeScript == sptTaiViet
  check Rune(43744).unicodeScript == sptMeeteiMayek
  check Rune(65536).unicodeScript == sptLinearB
  check Rune(66176).unicodeScript == sptLycian
  check Rune(66208).unicodeScript == sptCarian
  check Rune(66304).unicodeScript == sptOldItalic
  check Rune(66352).unicodeScript == sptGothic
  check Rune(66384).unicodeScript == sptOldPermic
  check Rune(66432).unicodeScript == sptUgaritic
  check Rune(66464).unicodeScript == sptOldPersian
  check Rune(66560).unicodeScript == sptDeseret
  check Rune(66640).unicodeScript == sptShavian
  check Rune(66688).unicodeScript == sptOsmanya
  check Rune(66736).unicodeScript == sptOsage
  check Rune(66816).unicodeScript == sptElbasan
  check Rune(66864).unicodeScript == sptCaucasianAlbanian
  check Rune(67072).unicodeScript == sptLinearA
  check Rune(67584).unicodeScript == sptCypriot
  check Rune(67648).unicodeScript == sptImperialAramaic
  check Rune(67680).unicodeScript == sptPalmyrene
  check Rune(67712).unicodeScript == sptNabataean
  check Rune(67808).unicodeScript == sptHatran
  check Rune(67840).unicodeScript == sptPhoenician
  check Rune(67872).unicodeScript == sptLydian
  check Rune(67968).unicodeScript == sptMeroiticHieroglyphs
  check Rune(68000).unicodeScript == sptMeroiticCursive
  check Rune(68096).unicodeScript == sptKharoshthi
  check Rune(68192).unicodeScript == sptOldSouthArabian
  check Rune(68224).unicodeScript == sptOldNorthArabian
  check Rune(68288).unicodeScript == sptManichaean
  check Rune(68352).unicodeScript == sptAvestan
  check Rune(68416).unicodeScript == sptInscriptionalParthian
  check Rune(68448).unicodeScript == sptInscriptionalPahlavi
  check Rune(68480).unicodeScript == sptPsalterPahlavi
  check Rune(68608).unicodeScript == sptOldTurkic
  check Rune(68736).unicodeScript == sptOldHungarian
  check Rune(68864).unicodeScript == sptHanifiRohingya
  check Rune(69376).unicodeScript == sptOldSogdian
  check Rune(69424).unicodeScript == sptSogdian
  check Rune(69632).unicodeScript == sptBrahmi
  check Rune(69760).unicodeScript == sptKaithi
  check Rune(69840).unicodeScript == sptSoraSompeng
  check Rune(69888).unicodeScript == sptChakma
  check Rune(69968).unicodeScript == sptMahajani
  check Rune(70016).unicodeScript == sptSharada
  check Rune(70144).unicodeScript == sptKhojki
  check Rune(70272).unicodeScript == sptMultani
  check Rune(70320).unicodeScript == sptKhudawadi
  check Rune(70400).unicodeScript == sptGrantha
  check Rune(70656).unicodeScript == sptNewa
  check Rune(70784).unicodeScript == sptTirhuta
  check Rune(71040).unicodeScript == sptSiddham
  check Rune(71168).unicodeScript == sptModi
  check Rune(71296).unicodeScript == sptTakri
  check Rune(71424).unicodeScript == sptAhom
  check Rune(71680).unicodeScript == sptDogra
  check Rune(71840).unicodeScript == sptWarangCiti
  check Rune(72192).unicodeScript == sptZanabazarSquare
  check Rune(72272).unicodeScript == sptSoyombo
  check Rune(72384).unicodeScript == sptPauCinHau
  check Rune(72704).unicodeScript == sptBhaiksuki
  check Rune(72816).unicodeScript == sptMarchen
  check Rune(72960).unicodeScript == sptMasaramGondi
  check Rune(73056).unicodeScript == sptGunjalaGondi
  check Rune(73440).unicodeScript == sptMakasar
  check Rune(73728).unicodeScript == sptCuneiform
  check Rune(77824).unicodeScript == sptEgyptianHieroglyphs
  check Rune(82944).unicodeScript == sptAnatolianHieroglyphs
  check Rune(92736).unicodeScript == sptMro
  check Rune(92880).unicodeScript == sptBassaVah
  check Rune(92928).unicodeScript == sptPahawhHmong
  check Rune(93760).unicodeScript == sptMedefaidrin
  check Rune(93952).unicodeScript == sptMiao
  check Rune(94176).unicodeScript == sptTangut
  check Rune(94177).unicodeScript == sptNushu
  check Rune(113664).unicodeScript == sptDuployan
  check Rune(120832).unicodeScript == sptSignWriting
  check Rune(124928).unicodeScript == sptMendeKikakui
  check Rune(125184).unicodeScript == sptAdlam
  check Rune(0x1E4EB).unicodeScript == sptNagMundari
  check Rune(0x1E4EF).unicodeScript == sptNagMundari
  check Rune(0x10FFFF).unicodeScript == UnicodeScript(0)
  check "諸".runeAt(0).unicodeScript() == sptHan

test "Test all lowerCase":
  var i = 0
  for ca in allLowercase:
    check toSeq(ca.cp.Rune.lowerCase) == ca.cps.toRunes
    inc i
  check i == 1433
  var checked = newSeq[bool](maxCp+1)
  for ca in allLowercase:
    checked[ca.cp] = true
  for cp in 0 .. maxCp:
    if not checked[cp]:
      #if cp in [42951, 42953, 42997]:
      #  continue
      if cp in [11311, 42944, 42960, 42966, 42968] or
          (cp >= 66928 and cp <= 66965):  # unicode 14
        continue
      if toSeq(cp.Rune.lowerCase) != @[cp.Rune]:
        echo $cp
      check toSeq(cp.Rune.lowerCase) == @[cp.Rune]

test "Test lowerCase":
  check toSeq('A'.ord.Rune.lowerCase) == @['a'.ord.Rune]
  check toSeq('Z'.ord.Rune.lowerCase) == @['z'.ord.Rune]
  check toSeq(0x24BD.Rune.lowerCase) == @[0x24D7.Rune]
  check toSeq("Ⓗ".runeAt(0).lowerCase) == @["ⓗ".runeAt(0)]
  check toSeq('a'.ord.Rune.lowerCase) == @['a'.ord.Rune]
  check toSeq('z'.ord.Rune.lowerCase) == @['z'.ord.Rune]
  check toSeq('0'.ord.Rune.lowerCase) == @['0'.ord.Rune]
  check toSeq('9'.ord.Rune.lowerCase) == @['9'.ord.Rune]
  check toSeq("諸".runeAt(0).lowerCase) == @["諸".runeAt(0)]
  check toSeq(0x0130.Rune.lowerCase) == @[0x0069.Rune, 0x0307.Rune]
  check toSeq(0x0049.Rune.lowerCase) == @['i'.ord.Rune]

test "Test lowerCase Ascii":
  var letters = newSeq[Rune]()
  for c in 'a'.ord .. 'z'.ord:
    letters.add(c.Rune)
  var i = 0
  for c in 'A'.ord .. 'Z'.ord:
    check toSeq(c.Rune.lowerCase) == @[letters[i]]
    inc i
  check i == letters.len

test "Test all upperCase":
  var i = 0
  for ca in allUppercase:
    check toSeq(ca.cp.Rune.upperCase) == ca.cps.toRunes
    inc i
  check i == 1525
  var checked = newSeq[bool](maxCp+1)
  for ca in allUppercase:
    checked[ca.cp] = true
  for cp in 0 .. maxCp:
    #if cp in [42952, 42954, 42998]:
    #  continue
    if not checked[cp]:
      if toSeq(cp.Rune.upperCase) != @[cp.Rune]:
        echo $cp
      check toSeq(cp.Rune.upperCase) == @[cp.Rune]

test "Test upperCase":
  check toSeq('a'.ord.Rune.upperCase) == @['A'.ord.Rune]
  check toSeq('z'.ord.Rune.upperCase) == @['Z'.ord.Rune]
  check toSeq(0x24D7.Rune.upperCase) == @[0x24BD.Rune]
  check toSeq("ⓗ".runeAt(0).upperCase) == @["Ⓗ".runeAt(0)]
  check toSeq('A'.ord.Rune.upperCase) == @['A'.ord.Rune]
  check toSeq('Z'.ord.Rune.upperCase) == @['Z'.ord.Rune]
  check toSeq('0'.ord.Rune.upperCase) == @['0'.ord.Rune]
  check toSeq('9'.ord.Rune.upperCase) == @['9'.ord.Rune]
  check toSeq("諸".runeAt(0).upperCase) == @["諸".runeAt(0)]
  check toSeq('i'.ord.Rune.upperCase) == @['I'.ord.Rune]
  check toSeq(0x00DF.Rune.upperCase) == @[0x0053.Rune, 0x0053.Rune]
  check toSeq(0x0130.Rune.upperCase) == @[0x0130.Rune]
  check toSeq(0xFB00.Rune.upperCase) == @[0x0046.Rune, 0x0046.Rune]
  check toSeq("ﬃ".runeAt(0).upperCase) == @['F'.ord.Rune, 'F'.ord.Rune, 'I'.ord.Rune]
  check toSeq(0xFB03.Rune.upperCase) == @[0x0046.Rune, 0x0046.Rune, 0x0049.Rune]
  check toSeq(0x1FF6.Rune.upperCase) == @[0x03A9.Rune, 0x0342.Rune]

test "Test upperCase Ascii":
  var letters = newSeq[Rune]()
  for c in 'A'.ord .. 'Z'.ord:
    letters.add(c.Rune)
  var i = 0
  for c in 'a'.ord .. 'z'.ord:
    check toSeq(c.Rune.upperCase) == @[letters[i]]
    inc i
  check i == letters.len

test "Test all titleCase":
  var i = 0
  for ca in allTitlecase:
    check toSeq(ca.cp.Rune.titleCase) == ca.cps.toRunes
    inc i
  check i == 1452
  var checked = newSeq[bool](maxCp+1)
  for ca in allTitlecase:
    checked[ca.cp] = true
  for cp in 0 .. maxCp:
    #if cp in [42954, 42998, 42952]:
    #  continue
    if not checked[cp]:
      if toSeq(cp.Rune.titleCase) != @[cp.Rune]:
        echo $cp
      check toSeq(cp.Rune.titleCase) == @[cp.Rune]

test "Test titleCase":
  check toSeq('a'.ord.Rune.titleCase) == @['A'.ord.Rune]
  check toSeq('z'.ord.Rune.titleCase) == @['Z'.ord.Rune]
  check toSeq(0x24D7.Rune.titleCase) == @[0x24BD.Rune]
  check toSeq("ⓗ".runeAt(0).titleCase) == @["Ⓗ".runeAt(0)]
  check toSeq('A'.ord.Rune.titleCase) == @['A'.ord.Rune]
  check toSeq('Z'.ord.Rune.titleCase) == @['Z'.ord.Rune]
  check toSeq('0'.ord.Rune.titleCase) == @['0'.ord.Rune]
  check toSeq('9'.ord.Rune.titleCase) == @['9'.ord.Rune]
  check toSeq("諸".runeAt(0).titleCase) == @["諸".runeAt(0)]
  check toSeq('i'.ord.Rune.titleCase) == @['I'.ord.Rune]
  # differs from upperCase
  check toSeq("ß".runeAt(0).titleCase) == @['S'.ord.Rune, 's'.ord.Rune]
  check toSeq(0x00DF.Rune.titleCase) == @[0x0053.Rune, 0x0073.Rune]
  check toSeq(0x0130.Rune.titleCase) == @[0x0130.Rune]
  check toSeq(0xFB00.Rune.titleCase) == @[0x0046.Rune, 0x0066.Rune]
  check toSeq(0xFB03.Rune.titleCase) == @[0x0046.Rune, 0x0066.Rune, 0x0069.Rune]
  check toSeq(0x1FF6.Rune.titleCase) == @[0x03A9.Rune, 0x0342.Rune]

test "Test titleCase Ascii":
  var letters = newSeq[Rune]()
  for c in 'A'.ord .. 'Z'.ord:
    letters.add(c.Rune)
  var i = 0
  for c in 'a'.ord .. 'z'.ord:
    check toSeq(c.Rune.titleCase) == @[letters[i]]
    inc i
  check i == letters.len

test "Test all caseFold":
  var i = 0
  for ca in allCaseFold:
    check toSeq(ca.cp.Rune.caseFold) == ca.cps.toRunes
    inc i
  check i == 1530
  var checked = newSeq[bool](maxCp+1)
  for ca in allcaseFold:
    checked[ca.cp] = true
  for cp in 0 .. maxCp:
    #if cp in [42951, 42953, 42997]:
    #  continue
    if not checked[cp]:
      if toSeq(cp.Rune.caseFold) != @[cp.Rune]:
        echo $cp
      check toSeq(cp.Rune.caseFold) == @[cp.Rune]

test "Test caseFold":
  check toSeq(0x0130.Rune.caseFold) == @[0x0069.Rune, 0x0307.Rune]
  check toSeq(0x0132.Rune.caseFold) == @[0x0133.Rune]
  check toSeq(0x1E921.Rune.caseFold) == @[0x1E943.Rune]
  check toSeq(0x1F88.Rune.caseFold) == @[0x1F00.Rune, 0x03B9.Rune]
  check toSeq("ᾈ".runeAt(0).caseFold) == @["ἀ".runeAt(0), "ι".runeAt(0)]

test "Test word-break data":
  var changed = 0
  var i = 0
  for wb in allWordBreak:
    for cp in wb.cpFirst .. wb.cpLast:
      changed += int(cp.Rune.wordBreakProp != wb.prop.SgWord)
      inc i
  check i == maxCp+1
  check changed == 223

test "Test wordBreakProp":
  check 0x10FFFF.Rune.wordBreakProp == sgwOther
  check 0x0022.Rune.wordBreakProp == sgwDoubleQuote
  check 0x0027.Rune.wordBreakProp == sgwSingleQuote
  check 0x05D0.Rune.wordBreakProp == sgwHebrewLetter
  check 0x05D1.Rune.wordBreakProp == sgwHebrewLetter
  check 0x05EA.Rune.wordBreakProp == sgwHebrewLetter
  check 0x000D.Rune.wordBreakProp == sgwCr
  check 0x000A.Rune.wordBreakProp == sgwLf
  check 0x000B.Rune.wordBreakProp == sgwNewline
  check 0x000C.Rune.wordBreakProp == sgwNewline
  check 0x000C.Rune.wordBreakProp == sgwNewline
  check 0x2029.Rune.wordBreakProp == sgwNewline
  check 0x2028.Rune.wordBreakProp == sgwNewline
  check 0x0085.Rune.wordBreakProp == sgwNewline
  check 0x0300.Rune.wordBreakProp == sgwExtend
  check 0x036F.Rune.wordBreakProp == sgwExtend
  check 0x11A97.Rune.wordBreakProp == sgwExtend
  check 0x1F1E6.Rune.wordBreakProp == sgwRegionalIndicator
  check 0x1F1FF.Rune.wordBreakProp == sgwRegionalIndicator
  check 0x00AD.Rune.wordBreakProp == sgwFormat
  check 0xFF6F.Rune.wordBreakProp == sgwKatakana
  check 0x038C.Rune.wordBreakProp == sgwAletter
  check 0x003A.Rune.wordBreakProp == sgwMidLetter
  check 0x037E.Rune.wordBreakProp == sgwMidNum
  check 0x2024.Rune.wordBreakProp == sgwMidNumLet
  check 0x09EF.Rune.wordBreakProp == sgwNumeric
  check 0x203F.Rune.wordBreakProp == sgwExtendNumLet
  check 0x200D.Rune.wordBreakProp == sgwZwj
  check 0x205F.Rune.wordBreakProp == sgwWsegSpace
  check 0x1F61C.Rune.wordBreakProp == sgwExtendedPictographic
  check 0x1F61E.Rune.wordBreakProp == sgwExtendedPictographic
  check 0x1F6CC.Rune.wordBreakProp == sgwExtendedPictographic

test "Test collationElements":
  check [0x07F6.Rune].collationElements == @[
    CollationElement(
      level1: 0x0594'u16,
      level2: 0x0020'u16,
      level3: 0x0002'u16,
      shifted: true)]
  check [0x1FC1.Rune].collationElements == @[
    CollationElement(
      level1: 0x04E7'u16,
      level2: 0x0020'u16,
      level3: 0x0002'u16,
      shifted: true),
    CollationElement(
      level1: 0x0000'u16,
      level2: 0x002A'u16,
      level3: 0x0002'u16,
      shifted: false)]

when nimvm:  # works, but it's too slow to test this way
  discard
else:
  test "Test collationElements sanity check":
    for cp in 0 .. maxCp:
      check collationElements([cp.Rune]).len > 0
      check collationElements([cp.Rune]).len < 20
