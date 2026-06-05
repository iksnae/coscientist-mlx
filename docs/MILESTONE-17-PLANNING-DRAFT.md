# Milestone 17 Planning Draft

Date: 2026-06-05

Working name:

```txt
iCloud sync for studies (SwiftData + CloudKit)
```

## Status

Draft. Not yet promoted to MILESTONE-17-PLAN.md.

## Goal

Sync studies across the user's Apple devices so a study created on Mac
appears on iPhone and iPad (and back). Use SwiftData's CloudKit backing
(private database) with the project's real signing team, so it "just
works" via the user's iCloud account.

## Context

Operator (2026-06-05): "sync studies across devices … see my studies on
iPhone, iPad and Mac." M16 makes the `Study` model CloudKit-ready. The
apps are currently **ad-hoc signed** (`CODE_SIGN_IDENTITY "-"`, no team),
which CloudKit cannot use. The Khaos Machine distro
(`~/Spikes/khaos.machine/khaos-foundation`) establishes the team and
signing pattern to reuse:

- **Apple Team ID `G98TZJ75HL`** (Khalid Mills) — from the Developer ID
  cert / `.env`.
- A per-app `.entitlements` file + hardened runtime + Automatic signing.
- Notarization creds in a git-ignored `.env`
  (`APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID`) — for
  distribution, not needed for dev/local sync.

## Usage Scenarios

### Scenario 1: Cross-device studies

Expected behavior:

- Signed into the same iCloud account, a study created/edited on one
  device appears on the others within CloudKit's sync latency; deletes
  propagate; offline edits reconcile on reconnect.

### Scenario 2: Private + opt-in

Expected behavior:

- Studies live in the user's **private** CloudKit database (not public);
  with no iCloud account the app still works fully on-device (sync is
  additive, never required — local-first).

## Primary Scope

### Track A — Signing + entitlements (project.yml + entitlements files)

Switch both app targets to Automatic signing with
`DEVELOPMENT_TEAM = G98TZJ75HL` (drop the ad-hoc `CODE_SIGN_IDENTITY "-"`).
Add a `.entitlements` per app with
`com.apple.developer.icloud-container-identifiers`
(`iCloud.io.khaos.coscientist`) + `com.apple.developer.icloud-services`
(`CloudKit`) (+ the existing sandbox stance). Mirror Khaos's entitlements/
hardened-runtime approach. Document the `.env` notarization pattern for
later distribution.

### Track B — SwiftData CloudKit container (Apps)

Configure the `modelContainer` with a CloudKit private database
(`ModelConfiguration(... cloudKitDatabase: .private("iCloud.io.khaos.coscientist"))`),
shared by both apps. Verify the `Study` model passes the CloudKit
constraints (M16). Handle the no-account / first-sync states gracefully.

## Definition Of Done

- Both apps build **signed** with team `G98TZJ75HL` and the iCloud
  entitlement (the ad-hoc identity is replaced); `.entitlements` files in
  the repo.
- The SwiftData container uses the CloudKit private DB; the `Study` model
  is CloudKit-valid (no schema error at store init).
- With iCloud available, a study created on one build appears on another
  (manual two-device / two-simulator verification, recorded in closeout);
  with no iCloud account, the app runs fully on-device (no crash, sync
  simply inactive).
- `swift build` clean; `swift test` green (package tests are signing-
  independent).
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M17 tracking + closeout docs land with the final commit.

## Non-Goals

- Shared/public databases or study sharing between *different* users —
  private-DB single-user sync only.
- CI signing — CI runs package `swift test` (unsigned); the signed app
  build + sync verification is local/manual.
- Conflict-resolution UX beyond CloudKit/SwiftData defaults.

## Open Questions

- **iCloud container id.** `iCloud.io.khaos.coscientist` vs another prefix.
  Lean `iCloud.com.iksnae.coscientist` to match the existing bundle id
  prefix (`com.iksnae.coscientist.*`). Confirm at delivery.
- **`.automatic` vs `.private(container)`.** Lean explicit
  `.private(container)` so both apps share one container deterministically.

## Risk

- **Requires a real Apple Developer account + provisioning.** The iCloud
  container must exist in the portal (Automatic signing can create it);
  delivery needs the operator's signing assets. CI can't sign — gate the
  signed-app build to local. (Halt-and-flag if the team/container isn't
  available at grind time.)
- **SwiftData↔CloudKit schema strictness.** Any non-optional/no-default
  attribute or unique constraint breaks the store; M16 keeps it valid —
  re-verify before enabling.
- **Existing local studies.** Migrating the local store into the CloudKit
  store; verify no data loss on first run.

## Scope Class

Medium. Signing/entitlements switch + a CloudKit container config; small
code, but real-signing + provisioning dependency.

Estimated 2–3 (Track A) + 2–3 (Track B), ~5–6 commits (plus operator-side
provisioning).
