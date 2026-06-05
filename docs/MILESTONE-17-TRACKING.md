# Milestone 17 Tracking

Date: 2026-06-05

Milestone:

```txt
iCloud sync for studies (SwiftData + CloudKit)
```

## Status

Delivered — code + signing verified; live two-device sync observation operator-pending.

## Duration And Usage Tracking

| Field | Value |
| --- | --- |
| Planned start | 2026-06-05 |
| Actual start | 2026-06-05 |
| Actual end | — |
| Elapsed | — |
| Scope class | Medium |
| Confidence | Medium (code + signing verified; live two-device sync is operator-pending) |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| Both apps build **signed** with team `G98TZJ75HL` + the iCloud entitlement (ad-hoc replaced); `.entitlements` in the repo. | Done | macOS + iOS device builds BUILD SUCCEEDED; embedded entitlements show `team-identifier G98TZJ75HL` + `icloud-container-identifiers iCloud.com.iksnae.coscientist`. |
| SwiftData container uses the CloudKit private DB; `Study` is CloudKit-valid (no schema error at init). | Done | `StudyContainer.shared()` → `ModelConfiguration(cloudKitDatabase: .private(...))`; M16 kept the model CloudKit-valid. |
| With iCloud, a study on one build appears on another (manual two-device verification). | Pending | Requires the operator's two iCloud-signed devices; not observable in CI/headless. |
| With no iCloud account, the app runs fully on-device (no crash; sync inactive). | Done | `StudyContainer` falls back to a local-only store, then in-memory, on container-init failure. |
| `swift build` clean; `swift test` green (signing-independent). | Done | 152 tests / 36 suites green. |
| `import MLX*` only under `Sources/AICoScientistMLX/`. | Done | `git grep "import MLX" -- '*.swift'` → only `AICoScientistMLX/`. |
| `git diff --check` clean. | Done | Whitespace clean. |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Passed | Clean on Apple Silicon. |
| `swift test` | Passed | 152 tests / 36 suites. |
| macOS app build (signed) | Passed | Auto-provisioned; `Mac Team Provisioning Profile: com.iksnae.coscientist.demo`, iCloud entitlement embedded. |
| iOS device build (signed) | Passed | Auto-provisioned; `iOS Team Provisioning Profile: com.iksnae.coscientist.app`. |
| Two-device sync | Pending | Operator hardware. |
| `git diff --check` | Passed | Clean. |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| App/CloudKit team = `G98TZJ75HL`. | Accepted | Operator's paid team; container already provisioned under it. Distinct from the Developer ID distribution identity. |
| Container id `iCloud.com.iksnae.coscientist`, `.private(container)`. | Accepted | Matches bundle prefix; explicit private DB shared by both apps. |
| macOS demo switches from ad-hoc to real signing. | Accepted | CloudKit needs a provisioned identity; ad-hoc `"-"` can't carry the iCloud entitlement. |
| Local-first fallback (cloud → local → in-memory). | Accepted | App must work fully with no iCloud account (foundation). |
| Xcode Cloud: regenerate `.xcodeproj` in `ci_post_clone.sh`; deps public. | Accepted | Project is gitignored/generated; public deps need no auth/grant. |
