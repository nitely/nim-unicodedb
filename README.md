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

echo category("A".runeAt(0))  # 'L'etter, 'u'ppercase
# "Lu"

echo bidirectional(Rune(0x0660)) # 'A'rabic, 'N'umber
# "AN"

echo combining(Rune(0x860))
# 0

echo((quickCheck(Rune(0x0374)) and NfMasks.NfcQcNo.ord) != 0)
# true
```
[docs](https://nitely.github.io/nim-unicodedb/unicodedb/properties.html)

Names:
```nim
import unicode
import unicodedb

echo lookupStrict("LEFT CURLY BRACKET")  # '{'
# Rune(0x007B)

echo name("/".runeAt(0))
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

echo decomposition(Rune(0x0F9D))
# @[Rune(0x0F9C), Rune(0x0FB7)]
```
[docs](https://nitely.github.io/nim-unicodedb/unicodedb/decompositions.html)

## Related libraries

* [nim-graphemes](https://github.com/nitely/nim-graphemes)

## Storage

Storage is based on *multi-stage tables* and
*minimal perfect hashing* data-structures.

## Sizes

These are the current collections sizes:

* properties is 45KB. Used by `properties(1)`, `getCategory(1)`,
  `getBidirectional(1)`, `getCombining(1)` and `getQc(1)`
* compositions is 24KB. Used by: `composition(1)`
* decompositions is 149KB. Used by `decomposition(1)`
  and `canonicalDecomposition`
* names is 795KB. Used by `name(1)` and `lookup(1)`
* names (lookup) is 301KB. Used by `lookup(1)`

## Missing APIs

New APIs will be added from time to time. If you need
something that's missing, please open an issue or PR
(please, do mention the use-case).

## Tests

Initial tests are ran against [a dump of] Python's
`unicodedata` module to ensure correctness.
Also, the related libraries have their own custom tests
(some of the test data is provided by the unicode consortium).

## Contributing

I plan to work on most missing *related
libraries* (case folding, etc). If you would
like to work in one of those, please let me
know and I'll add it to the list. If you find
the required database data is missing, either open an
issue or a PR.

## LICENSE

MIT
