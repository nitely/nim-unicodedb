v0.13.1
==================

* Add `simpleCaseFold` API
* Add `hasCaseFolds` API

v0.13.0
==================

* Update to Unicode 16.0

v0.12.0
==================

* Update to Unicode 15.0

v0.11.0
==================

* Export unicode 14 scripts
* Drop Nim < 1.0 support

v0.10.0
==================

* Update to Unicode 14.0

v0.9.0
==================

* Update to Unicode 13.0

v0.8.0
==================

* Add full casing and folding data
* Add word-break segmentation data

v0.7.2
==================

* Make `properties` module work at CT

v0.7.1
==================

* Make `Types` work at CT (@timotheecour) PR #7

v0.7.0
==================

* Update to Unicode 12.1

v0.6.0
==================

* Drop support for Nim 0.17
* Add support for Nim 0.19 (no changes were required)
* Remove all derecated APIs

v0.5.2
==================

* Add Scripts data

v0.5.1
==================

* Add `categorySetMap` and `categoryMap`

v0.5.0
==================

* Add `unicodeCategory` functions
* Deprecate `category` functions
* Make `utm` types composable

v0.4.0
==================

* Update to Unicode 11

v0.3.2
==================

* Add East-Asian-Width data

v0.3.1
==================

* Breaking change: `composition(var Rune, Rune, Rune)`
  return `bool` instead of `int`
* Deprecated `composition(int, int)`, `decomposition(int)`,
  `canonicalDecomposition(int)`, `name(int)`, `properties(int)`,
  `category(int)`, `bidirectional(int)`, `combining(int)`,
  `quickCheck(int)` and `unicodeTypes(int)`

v0.2.5
==================

* Exceptionless `composition` API

v0.2.4
==================

* Minimal perf improvements
  for procs taking Runes
* Replaced generics by concrete
  types in APIs

v0.2.3
==================

* Add `utmWhiteSpace` type
* Add `utmWord` type

v0.2.2
==================

* Add missing data (int) types
* fix for Nim 0.17.2

v0.2.1
==================

* Fix `fnv32a` hashing

v0.2.0
==================

* Add types (derived core properties) API
* Add `contains` for `NfMask` usage,
  so `nfcQcNo in quickCheck(x)` is supported
* `NfMasks` was renamed to `NfMask`.
  It's no longer `{.pure.}` and initial
  letter of all properties are lowercase
* Fix `lookupStrict` for nim 0.17.3
* `EProps` was renamed to `UnicodeProp` and
  it's no longer `{.pure.}`. It's members
  have a `uprop` suffix (i.e: `upropCat`)
* `Props` was renamed to `UnicodeProps`

v0.1.0
==================

* Initial release
