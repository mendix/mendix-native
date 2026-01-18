# GitHub Actions CI/CD Documentation

This document describes the Continuous Integration setup for the mendix-native project.

## Overview

The CI pipeline runs on every pull request and includes:

1. **Linting** - Code quality checks
2. **Building** - iOS and Android example app builds
3. **Testing** - Automated harness tests on both platforms

## Tooling Versions

All workflows use standardized tooling versions to ensure consistency:

### Core Tools

| Tool             | Version  | Defined In                    |
| ---------------- | -------- | ----------------------------- |
| **Node.js**      | `24`     | `.nvmrc`                      |
| **Yarn**         | `4.12.0` | `package.json#packageManager` |
| **React Native** | `0.78.2` | `package.json`                |
| **React**        | `19.0.0` | `package.json`                |
| **TypeScript**   | `5.9.2`  | `package.json`                |

### Android Tooling

| Tool                    | Version                  | Defined In                     |
| ----------------------- | ------------------------ | ------------------------------ |
| **Java**                | `17` (Zulu distribution) | All Android workflows          |
| **Gradle**              | `8.12`                   | `gradle-wrapper.properties`    |
| **Android Build Tools** | `35.0.0`                 | `example/android/build.gradle` |
| **NDK**                 | `27.3.13750724`          | `example/android/build.gradle` |
| **Kotlin**              | `2.0.21`                 | `example/android/build.gradle` |
| **compileSdkVersion**   | `35`                     | `example/android/build.gradle` |
| **targetSdkVersion**    | `35`                     | `example/android/build.gradle` |
| **minSdkVersion**       | `24`                     | `example/android/build.gradle` |

### iOS Tooling

| Tool          | Version                             | Defined In                       |
| ------------- | ----------------------------------- | -------------------------------- |
| **Xcode**     | `26.2`                              | All iOS workflows                |
| **iOS SDK**   | `26.2`                              | Xcode 26.2 includes iOS 26.2 SDK |
| **Ruby**      | `3.2`                               | `ios.yml`                        |
| **CocoaPods** | `>= 1.13` (excludes 1.15.0, 1.15.1) | `example/Gemfile`                |

> **Note for Local Development:** GitHub Actions `macos-latest` runners use Xcode 26.2 as the default.  
> Your local machine may have a different Xcode version. The workflows are configured to match GitHub Actions'  
> environment. Local development can use any compatible Xcode version, but ensure simulator devices specified  
> in `rn-harness.config.mjs` are available on your system.

### Test Configuration

| Tool                     | Version               | Defined In              |
| ------------------------ | --------------------- | ----------------------- |
| **React Native Harness** | `1.0.0-alpha.21`      | `package.json`          |
| **Android Emulator**     | Pixel_API_34 (API 34) | `rn-harness.config.mjs` |
| **iOS Simulator**        | iPhone 17 (iOS 26.2) | `rn-harness.config.mjs` |

### GitHub Actions

All actions are pinned to specific commit SHAs for security and reproducibility:

| Action                                   | Version  | SHA                                        |
| ---------------------------------------- | -------- | ------------------------------------------ |
| `actions/checkout`                       | v4.2.2   | `93cb6efe18208431cddfb8368fd83d5badbf9bfd` |
| `actions/setup-node`                     | v4.2.2   | `49933ea5288caeca8642d1e84afbd3f7d6820020` |
| `actions/setup-java`                     | v4.7.1   | `f2beeb24e141e01a676f977032f5a29d81c9e27e` |
| `actions/cache`                          | v4.2.0   | `0057852bfaa89a56745cba8c7296529d2fc39830` |
| `ruby/setup-ruby`                        | v1.204.0 | `d697be2f83c6234b20877c3b5eac7a7f342f0d0c` |
| `android-actions/setup-android`          | v3.2.1   | `9fc6c4e9069bf8d3d10b2204b1fb8f6ef7065407` |
| `reactivecircus/android-emulator-runner` | v2.33.0  | `b530d96654c385303d652368551fb075bc2f0b6b` |

> **Note on iOS Simulator:** We use a custom shell script (`.github/scripts/launch-ios-simulator.sh`) instead of `futureware-tech/simulator-action` for better reliability and faster boot times. The action was sometimes unstable and could hang for hours without response.

### Version Consistency Rules

**IMPORTANT**: When updating versions, maintain consistency:

1. **iOS Simulator Device**: Must match between:

   - `rn-harness.config.mjs` (test configuration)
   - `ios.yml` (xcodebuild destination)
   - `example/package.json` (ios:simulator:build script)
   - Must be available in the specified Xcode version

2. **Xcode Version**: Must match in:

   - `ios.yml` (xcode-select command and DEVELOPER_DIR env var)
   - iOS simulator version in harness config must be compatible

3. **Android Emulator Device**: Must match between:

   - `rn-harness.config.mjs` (test configuration)
   - `android.yml` (AVD_NAME environment variable)

4. **NDK Version**: Must match between:

   - `example/android/build.gradle` (ndkVersion)
   - `android.yml` (sdkmanager install command and cache path)

5. **Java Version**: Must be specified in:

   - `android.yml` (Setup Java step)

6. **Ruby Version**: Must satisfy:

   - `ios.yml` specification (3.2)
   - `example/Gemfile` requirement (>= 2.6.10)
   - `ios.yml` working-directory must point to `example` (where Gemfile lives)

7. **React Native Harness**: Must match between:
   - `example/package.json`
   - All harness platform packages (`@react-native-harness/*`)

## Workflows

#### 1. Lint (`.github/workflows/lint.yml`)

- Runs ESLint and TypeScript checks

#### 2. Android Build & Test (`.github/workflows/android.yml`)

**Single integrated job that:**

- Builds the Android example app (debug APK)
- Sets up Android emulator
- Runs harness tests
- Runs on: `ubuntu-latest`
- Uses: Java 17, Android SDK, NDK 27.3.13750724

#### 3. iOS Build & Test (`.github/workflows/ios.yml`)

**Single integrated job that:**

- Builds the iOS example app for simulator
- Sets up iOS simulator
- Runs harness tests
- Runs on: `macos-latest`
- Uses: Xcode 26.2, Ruby 3.2, CocoaPods

## Test Configuration

The harness tests are configured in `example/rn-harness.config.mjs`:

```javascript
runners: [
  androidPlatform({
    name: 'android',
    device: androidEmulator('Pixel_API_34'),
    bundleId: 'mendixnative.example',
  }),
  applePlatform({
    name: 'ios',
    device: appleSimulator('iPhone 17', '26.2'),
    bundleId: 'mendixnative.example',
  }),
];
```

The workflows handle device setup automatically:

- **Android**: Uses `reactivecircus/android-emulator-runner` to launch the emulator
- **iOS**: Uses a custom script (`.github/scripts/launch-ios-simulator.sh`) that launches the simulator with specific OS version pinning

## Running Tests Locally

### iOS

Make sure `iPhone 17 (iOS 26.2)` simulator is up and running. You can use the launch script:

```bash
# Launch simulator automatically
./.github/scripts/launch-ios-simulator.sh "iPhone 17" "26.2"

# Then run tests
corepack enable
yarn install
yarn prepare
cd example
yarn pod
yarn harness:ios:with:build
```

### Android

Make sure emulator with name `Pixel_API_34` is up and running

```bash
corepack enable
yarn install
yarn prepare
cd example
yarn harness:android:with:build
```

## Troubleshooting

### Device/Emulator Issues

**Android emulator fails to boot or tests time out:**

- Check AVD cache - clear `avd-*` entries if corrupted
- Verify KVM is enabled (workflows handle this automatically)
- Check emulator logs in workflow output
- Ensure AVD_NAME matches harness config (`Pixel_API_34`)

**iOS simulator not found or fails to boot:**

- Verify simulator model exists in Xcode version (`iPhone 17`)
- Check iOS version compatibility (`26.2`)
- Review simulator launch script logs for errors
- Ensure device name matches harness config exactly
- Check if `jq` is installed (script requires it for JSON parsing)
- Simulator script automatically handles stuck processes and timeouts

## References

- [React Native Harness Documentation](https://www.react-native-harness.dev/)
- [React Native Harness CI/CD Guide](https://www.react-native-harness.dev/docs/guides/ci-cd)
- [Android Emulator Runner Action](https://github.com/ReactiveCircus/android-emulator-runner)
