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
