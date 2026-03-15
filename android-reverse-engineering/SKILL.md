---
name: android-reverse-engineering
description: Decompile Android APK, XAPK, JAR, and AAR packages with jadx or Fernflower/Vineflower, inspect manifests and package structure, trace call flows from UI code to the network layer, and extract/document HTTP API endpoints. Use when Codex needs to reverse engineer an Android app or library, analyze decompiled output, find Retrofit/OkHttp/Volley usage, recover auth flows, or map API calls in software you are authorized to inspect.
---

# Android Reverse Engineering

## Overview

Use the bundled scripts to verify dependencies, decompile the target package, inspect the project structure, trace call flows, and document extracted APIs.

Resolve the installed skill directory before running bundled scripts:

```bash
SKILL_DIR="${CODEX_HOME:-$HOME/.codex}/skills/android-reverse-engineering"
```

On Windows, prefer running the shell scripts from WSL or Git Bash. The dependency installer automates Linux and macOS package managers; on Windows, follow the manual steps in `references/setup-guide.md`.

Use this skill only for software that you own or are explicitly authorized to analyze.

## Phase 1: Verify Dependencies

Run the dependency checker before decompiling:

```bash
bash "$SKILL_DIR/scripts/check-deps.sh"
```

Interpret the output as follows:

- `INSTALL_REQUIRED:<dep>` means the dependency must be installed before continuing.
- `INSTALL_OPTIONAL:<dep>` means the dependency is recommended but not blocking.

If a required dependency is missing, install it with:

```bash
bash "$SKILL_DIR/scripts/install-dep.sh" <dep>
```

If the installer cannot complete automatically, use the manual instructions in `references/setup-guide.md`, then run the dependency check again.

## Phase 2: Decompile

Run the decompile wrapper against the target `.apk`, `.xapk`, `.jar`, or `.aar`:

```bash
bash "$SKILL_DIR/scripts/decompile.sh" [OPTIONS] <file>
```

Use these options when needed:

- `-o <dir>` to set a custom output directory.
- `--deobf` to enable deobfuscation.
- `--no-res` to skip resources for faster code-only output.
- `--engine jadx|fernflower|both` to choose the decompiler.

Choose the engine with this rule of thumb:

| Situation | Engine |
|---|---|
| First pass on an APK | `jadx` |
| JAR or AAR library analysis | `fernflower` |
| jadx output is noisy or broken | `both` |
| Complex lambdas, generics, or streams | `fernflower` |
| Fast overview of a large package | `jadx --no-res` |

For `.xapk` bundles, let the script extract all embedded APKs and decompile each one into its own subdirectory. For Fernflower on `.apk` or `.aar`, ensure `dex2jar` is installed first.

Read `references/jadx-usage.md` and `references/fernflower-usage.md` for CLI details and troubleshooting.

## Phase 3: Analyze Structure

Read the generated output in this order:

1. Read `AndroidManifest.xml` and identify the launcher activity, application class, exported components, and permissions.
2. Survey the package structure under `sources/` and separate first-party code from libraries.
3. Look for `api`, `network`, `data`, `repository`, `service`, `retrofit`, and `http` packages first.
4. Identify the app architecture, such as MVP, MVVM, or Clean Architecture, before tracing flows deeper.

## Phase 4: Trace Call Flows

Trace execution from entry points down to the network layer:

1. Start at the launcher activity, deep-link entry point, service, receiver, or `Application` class.
2. Follow initialization in `Application.onCreate()` to locate DI wiring, HTTP clients, interceptors, and base URLs.
3. Follow user actions through click handlers, fragments, presenters, view models, repositories, and API service interfaces.
4. If Dagger or Hilt is present, inspect modules and bindings to resolve interface implementations.
5. If code is obfuscated, anchor on string literals, Retrofit annotations, URL constants, auth headers, and third-party API usage.

Read `references/call-flow-analysis.md` for deeper tracing patterns and grep strategies.

## Phase 5: Extract and Document APIs

Run the API search script for a broad pass:

```bash
bash "$SKILL_DIR/scripts/find-api-calls.sh" <output>/sources/
```

Run targeted passes when needed:

```bash
bash "$SKILL_DIR/scripts/find-api-calls.sh" <output>/sources/ --retrofit
bash "$SKILL_DIR/scripts/find-api-calls.sh" <output>/sources/ --urls
bash "$SKILL_DIR/scripts/find-api-calls.sh" <output>/sources/ --auth
```

For each discovered endpoint, extract:

- HTTP method and path
- Base URL
- Path, query, header, and body parameters
- Authentication mechanism
- Response type
- Caller chain from UI entry point to network invocation

Document each endpoint in this format:

```markdown
### `METHOD /path`

- **Source**: `com.example.api.ApiService` (`ApiService.java:42`)
- **Base URL**: `https://api.example.com/v1`
- **Path params**: `id` (`String`)
- **Query params**: `page` (`int`), `limit` (`int`)
- **Headers**: `Authorization: Bearer <token>`
- **Request body**: `{ "email": "string", "password": "string" }`
- **Response**: `ApiResponse<User>`
- **Called from**: `LoginActivity -> LoginViewModel -> UserRepository -> ApiService`
```

Read `references/api-extraction-patterns.md` for library-specific search patterns and documentation tips.

## Deliverables

Produce these outputs at the end of the workflow:

1. Decompiled source in the output directory.
2. An architecture summary covering app structure and major packages.
3. API documentation for all recovered endpoints.
4. A call-flow map for the critical features, especially authentication and primary user journeys.

## References

- `references/setup-guide.md` for dependency setup and Windows notes.
- `references/jadx-usage.md` for jadx workflows and flags.
- `references/fernflower-usage.md` for Fernflower and Vineflower usage.
- `references/api-extraction-patterns.md` for API search patterns.
- `references/call-flow-analysis.md` for flow-tracing techniques.
