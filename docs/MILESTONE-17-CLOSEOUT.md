# Milestone 17 Closeout

Date: 2026-06-05

Milestone:

```txt
iCloud sync for studies (SwiftData + CloudKit)
```

## Status

Delivered (code + signing verified). One acceptance — live two-device
sync observation — is **operator-pending** (needs two iCloud-signed
devices); everything reproducible without that hardware is done.

## Delivered

### Track A — Signing + entitlements (project.yml + entitlements files)

- `project.yml` base now signs **Automatic under team `G98TZJ75HL`** (the
  paid Khaos team). The macOS demo dropped its ad-hoc `CODE_SIGN_IDENTITY
  "-"` and signs like the iOS app (CloudKit needs a provisioned identity);
  it stays non-sandboxed for HF/model-cache access.
- Per-app `.entitlements` (`Apps/iOS/CoScientistApp.entitlements`,
  `Apps/macOS/CoScientistDemo.entitlements`): iCloud container
  `iCloud.com.iksnae.coscientist`, `icloud-services = CloudKit`, ubiquity
  KV-store, and `aps-environment` for sync pushes. iOS also sets the
  `remote-notification` background mode.
- Verified: both apps build **signed** with `-allowProvisioningUpdates`;
  the embedded entitlements carry `team-identifier G98TZJ75HL` +
  `icloud-container-identifiers iCloud.com.iksnae.coscientist`. The
  container is already registered under the team (auto-provisioning
  succeeded headlessly).

### Track B — SwiftData CloudKit container (Apps)

- `StudyContainer.shared()` builds the `ModelContainer` on the **CloudKit
  private database** (`ModelConfiguration(... cloudKitDatabase:
  .private("iCloud.com.iksnae.coscientist"))`), shared by both apps.
- **Local-first** fallback: cloud → local-only store → in-memory, so the
  app runs fully with no iCloud account / unprovisioned entitlement and
  never crashes at store init. The `Study` model is CloudKit-valid (M16:
  all attributes optional/defaulted, no unique constraints).

### Xcode Cloud readiness

- `ci_scripts/ci_post_clone.sh` regenerates the gitignored `.xcodeproj`
  from `project.yml` via xcodegen after clone. All SwiftPM dependencies
  are public GitHub HTTPS repos (apple/*, ml-explore/*, huggingface/* incl.
  swift-jinja + transitive ibireme/yyjson, swiftgraphs/Grape) — resolution
  needs **no credentials and no "Grant Access"** (that step is only for
  private packages).

## Validation

```txt
swift build                                          # clean
swift test                                           # 152 tests / 36 suites green
xcodebuild … CoScientistDemo -allowProvisioningUpdates   # signed, iCloud entitlement embedded
xcodebuild … CoScientistApp  generic/platform=iOS …      # signed device build SUCCEEDED
codesign -d --entitlements                            # team G98TZJ75HL + iCloud container
git grep "import MLX" -- '*.swift'                    # only AICoScientistMLX/
git diff --check                                      # clean
```

**Not yet observed:** an edit on one device appearing on another. That
needs two devices signed into the same iCloud account and is the single
remaining manual acceptance.

## Retrospective

What worked:

- The container already existed under `G98TZJ75HL` (from a prior Xcode
  capability add), so `-allowProvisioningUpdates` signed both apps with the
  iCloud entitlement headlessly — no manual portal step was needed after
  all.
- Reusing the M7 hosted-backing mental model wasn't needed; SwiftData's
  native CloudKit backing made Track B a small container-config change.
- M16's CloudKit-ready model paid off: no schema changes were required.
- The local-first fallback keeps the app robust for unsigned/no-account
  builds and contributors without the team.

What to improve / watch:

- **Team split.** The app/CloudKit dev team (`G98TZJ75HL`) is the same org
  as Khaos's Developer ID, but signing used a member `Apple Development`
  cert; for App Store/TestFlight distribution a separate distribution cert
  + profile is still needed (future work).
- **Push for live sync.** `aps-environment` + remote-notification are set,
  but instant cross-device updates depend on APNs; without it, sync
  reconciles on launch/foreground. Confirm liveness during device testing.
- **Existing local studies → CloudKit store migration.** Verify no data
  loss on first run with the CloudKit container.

Carry forward:

- **Live two-device sync verification** (operator) — the open acceptance.
- **M18 — Distributed compute feasibility spike** (drafted, next).
- Candidate themes: multi-indicator run progress; model registry sync;
  parity-test harness; native FM tool calling.
- Standing: distribution signing (App Store/TestFlight) if the apps ship;
  prune unused `SettingsStore` fields.
