# Changelog

All notable changes to `mendix-native` package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [v0.4.0] - 2026-04-17

- We upgraded `@op-engineering/op-sqlite` from v15.0.7 to v15.2.5.
- We upgraded core native stack dependencies, including React Native (v0.78.2 -> v0.83.4), React (v19.0.0 -> v19.2.4), and `@react-native-community/cli` (v18.0.1 -> v20.1.2).
- We updated supporting development tooling dependencies (ESLint, Commitlint, Prettier, Lefthook, TypeScript, Turbo, and Release It).

## [v0.3.2] - 2026-01-16

- We updated the `OPSqlite` with compatibility for ANdroid 16kb page alignment.

## [v0.3.1] - 2026-01-08

- We added `SessionCookieStore` to persist, restore and clear session cookies on iOS.

## [v0.3.0] - 2025-12-09

- We fixed an issue that caused a FileNotFoundException during file deletion operations.
- We updated mendix-native to support react v19 and react native v0.78.2.

## [v0.1.3] - 2025-12-05

- We introduced AndroidNavigationBar module to get navigation bar height and active status.

## [0.1.2] - 2025-11-17

- We upgraded mendix-native to use React Native’s New Architecture to improve performance and future compatibility.
