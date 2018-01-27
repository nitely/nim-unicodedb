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
