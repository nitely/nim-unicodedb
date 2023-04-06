# UnicodeDB

[![Build Status](https://img.shields.io/travis/nitely/nim-unicodedb.svg?style=flat-square)](https://travis-ci.org/nitely/nim-unicodedb)
[![licence](https://img.shields.io/github/license/nitely/nim-unicodedb.svg?style=flat-square)](https://raw.githubusercontent.com/nitely/nim-unicodedb/master/LICENSE)

This library aims to bring the unicode database to Nim. Main goal is
having O(1) access for every API and be lightweight in size.

> Note: this library doesn't provide Unicode Common Locale Data (UCLD / CLDR data)

## Install

```
nimble install unicodedb
```

## Compatibility

Nim +1.0.0

## Usage

### Properties

```nim
import unicode
import unicodedb/properties

assert Rune('A'.ord).unicodeCategory() == ctgLu  # 'L'etter, 'u'ppercase
assert Rune('A'.ord).unicodeCategory() in ctgLm+ctgLo+ctgLu+ctgLl+ctgLt
assert Rune('A'.ord).unicodeCategory() in ctgL

echo Rune(0x0660).bidirectional() # 'A'rabic, 'N'umber
# "AN"

echo Rune(0x860).combining()
# 0

echo nfcQcNo in Rune(0x0374).quickCheck()
# true
```
[docs](https://nitely.github.io/nim-unicodedb/unicodedb/properties.html)

### Names

```nim
import unicode
import unicodedb/names

echo lookupStrict("LEFT CURLY BRACKET")  # '{'
# Rune(0x007B)

echo "/".runeAt(0).name()
# "SOLIDUS"
```
[docs](https://nitely.github.io/nim-unicodedb/unicodedb/names.html)

### Compositions

```nim
import unicode
import unicodedb/compositions

echo composition(Rune(108), Rune(803))
# Rune(7735)
```
[docs](https://nitely.github.io/nim-unicodedb/unicodedb/compositions.html)

### Decompositions

```nim
import unicode
import unicodedb/decompositions

echo Rune(0x0F9D).decomposition()
# @[Rune(0x0F9C), Rune(0x0FB7)]
```
[docs](https://nitely.github.io/nim-unicodedb/unicodedb/decompositions.html)

### Types

```nim
import unicode
import unicodedb/types

assert utmDecimal in Rune(0x0030).unicodeTypes()
assert utmDigit in Rune(0x00B2).unicodeTypes()
assert utmNumeric in Rune(0x2CFD).unicodeTypes()
assert utmLowercase in Rune(0x1E69).unicodeTypes()
assert utmUppercase in Rune(0x0041).unicodeTypes()
assert utmCased in Rune(0x0041).unicodeTypes()
assert utmWhiteSpace in Rune(0x0009).unicodeTypes()
assert utmWord in Rune(0x1E69).unicodeTypes()

const alphaNumeric = utmLowercase + utmUppercase + utmNumeric
assert alphaNumeric in Rune(0x2CFD).unicodeTypes()
assert alphaNumeric in Rune(0x1E69).unicodeTypes()
assert alphaNumeric in Rune(0x0041).unicodeTypes()
```
[docs](https://nitely.github.io/nim-unicodedb/unicodedb/types.html)

### Widths

```nim
import unicode
import unicodedb/widths

assert "🕺".runeAt(0).unicodeWidth() == uwdtWide
```
[docs](https://nitely.github.io/nim-unicodedb/unicodedb/widths.html)

### Scripts

```nim
import unicode
import unicodedb/scripts

assert "諸".runeAt(0).unicodeScript() == sptHan
```
[docs](https://nitely.github.io/nim-unicodedb/unicodedb/scripts.html)

### Casing

```nim
import sequtils
import unicode
import unicodedb/casing

assert toSeq("Ⓗ".runeAt(0).lowerCase) == @["ⓗ".runeAt(0)]
assert toSeq("İ".runeAt(0).lowerCase) == @[0x0069.Rune, 0x0307.Rune]

assert toSeq("ⓗ".runeAt(0).upperCase) == @["Ⓗ".runeAt(0)]
assert toSeq("ﬃ".runeAt(0).upperCase) == @['F'.ord.Rune, 'F'.ord.Rune, 'I'.ord.Rune]

assert toSeq("ß".runeAt(0).titleCase) == @['S'.ord.Rune, 's'.ord.Rune]

assert toSeq("ᾈ".runeAt(0).caseFold) == @["ἀ".runeAt(0), "ι".runeAt(0)]
```
[docs](https://nitely.github.io/nim-unicodedb/unicodedb/casing.html)

### Segmentation

```nim
import unicode
import unicodedb/segmentation

assert 0x000B.Rune.wordBreakProp == sgwNewline
```
[docs](https://nitely.github.io/nim-unicodedb/unicodedb/segmentation.html)

## Related libraries

* [nim-unicodeplus](https://github.com/nitely/nim-unicodeplus)
* [nim-graphemes](https://github.com/nitely/nim-graphemes)
* [nim-segmentation](https://github.com/nitely/nim-segmentation)
* [nim-normalize](https://github.com/nitely/nim-normalize)

## Storage

Storage is based on *multi-stage tables* and
*minimal perfect hashing* data-structures.

## Sizes

These are the current collections sizes:

* properties is 40KB. Used by `properties(1)`, `category(1)`,
  `bidirectional(1)`, `combining(1)` and `quickCheck(1)`
* compositions is 12KB. Used by: `composition(1)`
* decompositions is 89KB. Used by `decomposition(1)`
  and `canonicalDecomposition(1)`
* names is 578KB. Used by `name(1)` and `lookupStrict(1)`
* names (lookup) is 241KB. Used by `lookupStrict(1)`

## Missing APIs

New APIs will be added from time to time. If you need
something that's missing, please open an issue or PR
(please, do mention the use-case).

## Upgrading Unicode version

> Note: PR's upgrading the unicode version
> won't get merged, open an issue instead!

* Run `nimble gen` to check there are no changes
  to `./src/*_data.nim`. If there are try an older
  Nim version and fix the generators accordingly
* Run `nimble gen_tests` to update all test data to current
  unicode version. The tests for a new unicode version run
  against the previous unicode version.
* Run tests and fix all failing tests. This should
  require just temporarily commenting out
  all checks for missing unicode points.
* Overwrite `./gen/UCD` data with
  [latest unicode UCD](http://unicode.org/Public/UCD/latest/ucd/UCD.zip).
* Run `nimble gen` to generate the new data.
* Run tests. Add checks for missing unicode points back.
  A handful of unicode points may have change its data, check
  the unicode changelog page, make sure they are correct and skip them.
* Note: starting Unicode 15 they added multiple @missing lines
  which breaks the assumption of a default prop for missing CPs
  and these lines need to be parsed (see DerivedBidiClass for example).
  So if they add this to more files, the data gen need fixing.
  Look for lines containing `# @missing` with a range other than `0000..10FFFF`. See [Missing_Conventions](https://www.unicode.org/reports/tr44/tr44-30.html#Missing_Conventions)

## Tests

Initial tests were ran against [a dump of] Python's
`unicodedata` module to ensure correctness.
Also, the related libraries have their own custom tests
(some of the test data is provided by the unicode consortium).

```
nimble test
```

## Contributing

I plan to work on most missing *related
libraries* (case folding, etc). If you would
like to work in one of those, please let me
know and I'll add it to the list. If you find
the required database data is missing, either open an
issue or a PR.

## LICENSE

MIT
