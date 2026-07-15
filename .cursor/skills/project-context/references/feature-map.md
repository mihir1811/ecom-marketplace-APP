# Feature Map

The source spec describes a journey, not a module breakdown — this file translates that
journey into the feature areas you'll actually scope, ticket, and build against. Use it to
decide where new logic belongs and what a feature area is and isn't responsible for. Each
area lists its purpose, what it owns, what it explicitly does not own, and the related
user-flow steps / business rules.

## 1. Authentication & Account
- **Owns:** sign-up/login, session management, the user's profile (public-facing).
- **Does not own:** the private face reference — that's a separate, more restricted asset
  (see Face Reference Enrollment below), not part of the public profile.
- **Related:** `user-flow.md` Step 1.

## 2. Group Management
- **Owns:** creating groups, generating join codes/invitations, join confirmation, group
  metadata (name, owner/admin, participant list), group settings.
- **Key entity:** a Group is the recognition and privacy boundary for everything below it —
  almost every other feature area needs a `group_id` in scope.
- **Related:** `user-flow.md` Step 2, `project-overview.md` Core Principle 4.

## 3. Face Reference Enrollment
- **Owns:** capturing the reference photo, running validation checks (blur, darkness,
  face size, multiple faces, partial visibility), storing the reference with strict access
  control, re-enrollment/retake flow.
- **Does not own:** the recognition/matching algorithm itself — enrollment only produces the
  reference asset that the recognition engine later compares against.
- **Critical constraint:** the reference photo is never exposed through any gallery, profile,
  export, or download path used by other members — treat its access control as a separate,
  stricter code path from group-photo access control, not a flag on the same one.
- **Related:** `user-flow.md` Step 3, `business-rules.md` (validation outcomes, privacy rules).

## 4. Camera & Capture
- **Owns:** the capture UI, showing the active group context (`Capturing for: <Group>`),
  writing captured photos to durable storage, and enqueuing each photo for processing.
- **Hard requirement:** this layer must never block the next shutter press on anything
  happening downstream (upload, detection, matching). If a feature request would make capture
  wait on processing, it belongs in a different feature area.
- **Related:** `user-flow.md` Steps 5–6, `project-overview.md` Core Principle 1.

## 5. Background Processing Pipeline
- **Owns:** the async orchestration that moves a photo through: saved → prepared → detected →
  analyzed → compared → confidence-evaluated → recipients-determined → distributed →
  completed. Owns retry/failure handling and status tracking per photo.
- **Does not own:** the actual detection/recognition logic (owned by the Recognition Engine)
  or the delivery/access-control logic (owned by Distribution) — this layer sequences and
  tracks work, it doesn't do the recognition math itself.
- **Related:** `user-flow.md` Step 7.

## 6. Face Detection & Recognition Engine
- **Owns:** detecting faces in a photo, generating similarity scores against the candidate
  set, ranking candidates, and applying the confidence-gap rule to decide accept/reject per
  face.
- **Candidate set scoping:** always scoped to the capturing photo's group (Principle 4) —
  never compare against the full user base or other groups.
- **Related:** `user-flow.md` Step 8, `business-rules.md` (confidence thresholds).

## 7. Recipient Determination & Distribution
- **Owns:** turning "these faces were confidently matched" into "these accounts are
  authorized to view this photo," and modeling the photo as a single asset with an access list
  rather than per-recipient copies.
- **Related:** `user-flow.md` Step 9, `business-rules.md` (single-asset distribution rule).

## 8. Personal Photo Collection ("Photos of Me")
- **Owns:** the cross-group personal feed of every photo where the user was confidently
  recognized, sourced from whatever groups they belong to.
- **Related:** `user-flow.md` Step 10.

## 9. Group Gallery / Group Workspace
- **Owns:** the shared group-level view — all photos captured for the group, participant list,
  group settings — as distinct from the personal "Photos of Me" feed.
- **Does not own:** exposing any individual's private reference photo or private match list to
  other members.

## 10. Privacy & Access Control (cross-cutting)
- Not a screen or a pipeline stage — a set of constraints every other feature area must respect:
  reference-photo privacy, group-scoped recognition, and access-list-based photo distribution.
  When in doubt about whether a new feature is allowed to expose something, check
  `business-rules.md` first.
