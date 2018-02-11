# UnicodeDB

[![Build Status](https://img.shields.io/travis/nitely/nim-unicodedb.svg?style=flat-square)](https://travis-ci.org/nitely/nim-unicodedb)
[![licence](https://img.shields.io/github/license/nitely/nim-unicodedb.svg?style=flat-square)](https://raw.githubusercontent.com/nitely/nim-unicodedb/master/LICENSE)

This library aims to bring the unicode database to Nim. Main goal is
having O(1) access for every API and be lightweight in size.

## Usage

Properties:
```nim
import unicode
import unicodedb

echo "A".runeAt(0).category()  # 'L'etter, 'u'ppercase
# "Lu"

echo Rune(0x0660).bidirectional() # 'A'rabic, 'N'umber
# "AN"

echo Rune(0x860).combining()
# 0

echo nfcQcNo in Rune(0x0374).quickCheck()
# true
```
[docs](https://nitely.github.io/nim-unicodedb/unicodedb/properties.html)

Names:
```nim
import unicode
import unicodedb

echo lookupStrict("LEFT CURLY BRACKET")  # '{'
# Rune(0x007B)

echo "/".runeAt(0).name()
# "SOLIDUS"
```
[docs](https://nitely.github.io/nim-unicodedb/unicodedb/names.html)

Compositions:
```nim
import unicode
import unicodedb

echo composition(Rune(108), Rune(803))
# Rune(7735)
```
[docs](https://nitely.github.io/nim-unicodedb/unicodedb/compositions.html)

Decompositions:
```nim
import unicode
import unicodedb

echo Rune(0x0F9D).decomposition()
# @[Rune(0x0F9C), Rune(0x0FB7)]
```
[docs](https://nitely.github.io/nim-unicodedb/unicodedb/decompositions.html)

Types:
```nim
import unicode
import unicodedb

assert utmDecimal in Rune(0x0030).unicodeTypes()
assert utmDigit in Rune(0x00B2).unicodeTypes()
assert utmNumeric in Rune(0x2CFD).unicodeTypes()
assert utmLowercase in Rune(0x1E69).unicodeTypes()
assert utmUppercase in Rune(0x0041).unicodeTypes()
assert utmCased in Rune(0x0041).unicodeTypes()
assert utmWhiteSpace in Rune(0x0009).unicodeTypes()
assert utmWord in Rune(0x1E69).unicodeTypes()
```
[docs](https://nitely.github.io/nim-unicodedb/unicodedb/types.html)

## Related libraries

* [nim-unicodeplus](https://github.com/nitely/nim-unicodeplus)
* [nim-graphemes](https://github.com/nitely/nim-graphemes)
* [nim-normalize](https://github.com/nitely/nim-normalize)

## Storage

Storage is based on *multi-stage tables* and
*minimal perfect hashing* data-structures.

## Sizes

These are the current collections sizes:

* properties is 45KB. Used by `properties(1)`, `category(1)`,
  `bidirectional(1)`, `combining(1)` and `quickCheck(1)`
* compositions is 13KB. Used by: `composition(1)`
* decompositions is 149KB. Used by `decomposition(1)`
  and `canonicalDecomposition(1)`
* names is 795KB. Used by `name(1)` and `lookupStrict(1)`
* names (lookup) is 301KB. Used by `lookupStrict(1)`

## Missing APIs

New APIs will be added from time to time. If you need
something that's missing, please open an issue or PR
(please, do mention the use-case).

## Tests

Initial tests are ran against [a dump of] Python's
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
