# Contributing to File Picker

:+1: :tada: First off, thanks for taking the time to contribute to _File Picker_! :tada: :+1:

The following is a first version of guidelines for contributing to _File Picker_. Feel free to propose changes to this document in a pull request.

## Issue a Pull Request

* **Dart code only:** before creating a pull request, please **write unit tests** if you added changes to Dart code under `lib/` (Java/Objective-C/Swift/Kotlin/C++ native code is currently not tested). Please ensure that the **code analysis** via `dart analyze` throws no errors. Please also make sure that your **code is formatted correctly** via `dart format`. You can take a look into our CI pipeline at `.github/workflows/main.yml` for further details. The CI pipeline is triggered automatically when you create a pull request on GitHub. All steps in our pipeline must run without errors.

* **This repository is a federated Melos workspace:** the `file_picker` package under `packages/file_picker` only contains the platform-agnostic Dart API. Each platform implementation lives in its own package with its own `pubspec.yaml` and `CHANGELOG.md` (`packages/file_picker_platform_interface`, `packages/file_picker_android`, `packages/file_picker_darwin`, `packages/file_picker_linux`, `packages/file_picker_windows`, `packages/file_picker_web`). Only bump the version and update the changelog of the package(s) you actually changed, not every package in the workspace.

* Please **update the package version** in the `pubspec.yaml` of every package you changed. We use [semantic versioning (SemVer)](https://semver.org/). TL;DR: increase the patch version when your pull request contains a bug fix. Increase the minor version when a new feature is added. Breaking changes to a package's public API should result in an increase in the major version. If a package's currently listed version is already published on pub.dev, bump to the next unpublished version rather than editing the published one.

* Please **update the changelog** in the `CHANGELOG.md` of every package you changed. Add a new level two heading with the updated package version to the top of the document, e.g. `## major.minor.patch`, and describe your changes below it. If your pull request is associated with an issue, please reference it. Each package's changelog is shown on its own pub.dev page (e.g. https://pub.dev/packages/file_picker/changelog, https://pub.dev/packages/file_picker_darwin/changelog).

## Releasing

Publishing to pub.dev is a manual step, triggered from the "Publish to pub.dev" GitHub Actions workflow (`.github/workflows/publish.yml`) via "Run workflow". It runs `melos publish`, which only publishes the packages whose local `pubspec.yaml` version is not yet published on pub.dev, every other package in the workspace is left untouched. There is no single version number for the whole repository, each package releases independently whenever its own version is bumped.

Before publishing for real, run the workflow once with the `dry_run` input left at its default (`true`) and check the job log, it lists exactly which packages and versions are about to be published. Once you are confident, run it again with `dry_run` set to `false`.

Every real (non-dry-run) publish also pushes a git tag per published package, named `<package_name>-v<version>` (e.g. `file_picker_darwin-v1.0.2`), pointing at the exact commit that was published. To check whether a given change made it into a published version of a package, find the tag for that version and see whether your commit is an ancestor of it (`git merge-base --is-ancestor <commit> <package_name>-v<version>`).
