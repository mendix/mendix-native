# Mendix Native

[![CI](https://github.com/mendix/mendix-native/actions/workflows/ci.yml/badge.svg)](https://github.com/mendix/mendix-native/actions/workflows/ci.yml)
[![Lint](https://github.com/mendix/mendix-native/actions/workflows/lint.yml/badge.svg)](https://github.com/mendix/mendix-native/actions/workflows/lint.yml)
[![Android](https://github.com/mendix/mendix-native/actions/workflows/android.yml/badge.svg)](https://github.com/mendix/mendix-native/actions/workflows/android.yml)
[![iOS](https://github.com/mendix/mendix-native/actions/workflows/ios.yml/badge.svg)](https://github.com/mendix/mendix-native/actions/workflows/ios.yml)

Mendix native mobile package for React Native applications.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js**: Version 24 (specified in `.nvmrc`)
- **Yarn**: Package manager (Yarn workspaces are required)
- **React Native development environment** (optional, only needed if running the example app): Follow the [React Native environment setup guide](https://reactnative.dev/docs/environment-setup)
  - For iOS: Xcode and CocoaPods
  - For Android: Android Studio and Android SDK

## Local Development Setup

This project is a monorepo managed using Yarn workspaces with:

- The library package in the root directory
- An example app in the `example/` directory

### 1. Clone the Repository

```bash
git clone https://github.com/YogendraShelke/mendix-native.git
cd mendix-native
```

### 2. Enable Corepack and Install Dependencies

```bash
corepack enable
yarn install
```

This will enable Yarn via Corepack and install dependencies for both the library and the example app.

### 3. Build the Library

```bash
yarn prepare
```

This compiles the TypeScript code and generates the `lib` folder.

### 4. Run the Example App

The example app demonstrates library usage and reflects your local changes in real-time.

#### Start Metro Bundler

```bash
yarn example start
```

#### Run on iOS

```bash
yarn example ios
```

Or open in Xcode:

```bash
yarn dev:ios
```

#### Run on Android

```bash
yarn example android
```

### 5. Development Workflow

#### Making Changes

- **JavaScript/TypeScript changes**: Automatically reflected without rebuild
- **Native code changes**: Require rebuilding the example app

#### Edit Native Code

**iOS (Objective-C/Swift):**

- Open `example/ios/MendixNativeExample.xcworkspace` in Xcode
- Find source files at: `Pods > Development Pods > mendix-native`

**Android (Java/Kotlin):**

- Open `example/android` in Android Studio
- Find source files under: `mendix-native` in the Android view

#### Verify Your Code

Run type checking:

```bash
yarn typecheck
```

Run linter:

```bash
yarn lint
```

Fix linting issues:

```bash
yarn lint --fix
```

Run tests:

```bash
yarn test
```

## Tests for iOS encrypted storage

New encrypted-storage values and persisted session cookies use
`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. They remain readable while
locked after the first unlock, but cannot migrate to a different device through
a backup. Legacy default-accessibility items are upgraded in place on successful
read without rotating keys or changing their values. Failed migrations are logged
and retried on later reads; they do not delete the item.

`MxEncryption.getItemStrict(key)` returns `null` only for an absent iOS Keychain
item and rejects inaccessible or failed reads. The existing `getItem` still
returns `null` for `errSecInteractionNotAllowed`. On Android the strict getter
delegates to the existing storage implementation; its policy is unchanged.
The strict getter requires a rebuilt native binary; do not deliver callers to
older binaries through OTA without matching native-dependency requirements.

Release this policy together with client recovery for an existing encrypted
offline database whose key is genuinely absent after device restore. Never
delete a database or generate a replacement key based on the legacy getter's
`null` result. Recovery must clear the affected session, recreate the database,
and require login/resync. Persistent authentication cookies are handled separately.

### Keychain tests

The example's Debug-only Keychain inspector supports the encryption harness
attribute and legacy-migration checks. Rebuild before running
`yarn example harness:ios:with:build`; these tests cannot run under ordinary Jest.

The CocoaPods `KeychainTests` test spec includes native cookie lifecycle,
migration-failure, and strict-read tests. Run `yarn example pod` to install its
test target, then run that target's tests on an iOS simulator in Xcode. These
tests use the test host's cookie store and Keychain accounts, not production
app storage. Physical-device backup/restore and locked-background checks remain
separate integration requirements.

For example, from the repository root:

```sh
xcodebuild test \
  -workspace example/ios/MendixNativeExample.xcworkspace \
  -scheme MendixNative-Unit-KeychainTests \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  -parallel-testing-enabled NO
```

### 6. Clean Build Artifacts

If you encounter build issues:

```bash
yarn clean
```

## Available Scripts

- `yarn install` - Install dependencies
- `yarn prepare` - Build the library
- `yarn typecheck` - Type-check with TypeScript
- `yarn lint` - Lint code with ESLint
- `yarn test` - Run unit tests
- `yarn clean` - Remove build artifacts
- `yarn example start` - Start Metro bundler
- `yarn example ios` - Run example app on iOS
- `yarn example android` - Run example app on Android
- `yarn dev:ios` - Build, install pods, and open iOS project

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed contribution guidelines.

---

## Release Process

This repository supports automated releases using a GitHub Actions workflow.
A manual fallback process is also documented below for situations where the workflow cannot be used.

## Automated Release (Recommended)

The automated workflow handles:

- Bumping the package version
- Building and generating the lib folder
- Creating the tarball (.tgz)
- Creating a GitHub Release with attached artifact
- Moving the Unreleased notes from CHANGELOG.md into a new version section
- Creating a pull request against master with updated files

### Steps

1. Go to GitHub → Actions → Manual Release.
2. Select Run workflow.
3. Choose the version bump type:
   - patch
   - minor
   - major
4. Run the workflow.

The workflow will:

- Update package.json version
- Run `yarn install && yarn prepare` to generate the build
- Run `yarn pack` to generate the .tgz file
- Create a new GitHub Release with:
  - tag = new version
  - release notes from the Unreleased section in CHANGELOG.md
  - the generated .tgz file attached
- Commit updated CHANGELOG.md and package.json
- Create a pull request:
  - branch: `release/<version>`
  - base: `master`

After the PR is merged, the release is complete.

## Manual Release (Fallback)

If the automated workflow fails, the release can be performed manually with the same steps.

### 1. Bump the Version

Choose one:

```bash
npm version patch
npm version minor
npm version major
```

This updates package.json locally (you'll commit this later).

### 2. Install and Build

```bash
yarn install
yarn prepare
```

The prepare script should generate the lib folder.

### 3. Generate the Tarball

```bash
yarn pack
```

This creates a file like:

```
package-name-vX.Y.Z.tgz
```

Keep this file for the release.

### 4. Update CHANGELOG.md

Move the content under Unreleased into a new version heading.

Example:

```markdown
## [Unreleased]

## [1.2.0] - 2025-01-15

<previous unreleased notes>
```

### 5. Commit Changes

```bash
git add CHANGELOG.md package.json
git commit -m "chore: release <version>"
git push
```

### 6. Create a GitHub Release Manually

1. Go to Releases → Draft a new release.
2. Use the version number as the tag and title.
3. Paste the notes you moved from the Unreleased section.
4. Upload the .tgz file from the yarn pack step.
5. Publish the release.

### 7. Create Pull Request (If Needed)

If your project requires PR-based updates, create a PR against master with the same changes you committed.

## Summary

Use the automated workflow whenever possible because it handles every repetitive step.
When needed, the fallback manual process mirrors the workflow exactly so releases remain consistent and predictable.
