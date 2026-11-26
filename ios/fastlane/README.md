fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios release

```sh
[bundle exec] fastlane ios release
```

Flutter ile IPA üretir, build'i ve metadata'yı App Store Connect'e yükler (incelemeye göndermez)

### ios submit_review

```sh
[bundle exec] fastlane ios submit_review
```

Yüklenmiş build'i incelemeye gönderir; onaydan sonra yayına elle alınır

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
