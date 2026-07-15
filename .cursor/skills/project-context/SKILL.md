---
name: project-context
description: Product and system context for the "Intelligent Group Photo Sharing Platform" — a group-based event photo app (weddings, trips, college/corporate/family events) where members capture photos continuously, enroll a private face reference, and the system auto-detects, recognizes, and privately distributes photos to whoever is confidently identified in them. Use whenever discussing, designing, building, or reviewing ANY part of this app — group creation/joining, face reference enrollment, camera/capture UX, the background processing pipeline, recognition confidence thresholds, photo distribution/access control, the "Photos of Me" collection, group galleries, or reference-photo privacy. Also trigger on project terms like "group code", "Capturing for:", "confidence gap", or example groups like "Ritu Wedding" / "Goa Trip". Load before coding or answering design questions so decisions stay consistent with the source spec; pair with a Flutter build skill when implementing screens.
---

# Project Context — Intelligent Group Photo Sharing Platform

This skill is the source of truth for one specific product: a group photography app that
solves "hundreds of photos taken, but the people in them never get them." It captures the
product spec so that every feature, screen, or answer about this app stays consistent with the
original design intent instead of drifting or getting reinvented per conversation.

## How to use this skill

Don't try to hold the whole spec in your head — pull the specific reference file(s) that match
what you're doing right now:

| Reference file | Read it when you're... |
|---|---|
| `references/project-overview.md` | Explaining the product, writing a pitch/PRD-style summary, or you need the *why* behind a design call. Contains the problem statement, solution summary, and the four core, non-negotiable product principles. |
| `references/user-flow.md` | Building or reviewing any screen or flow. Contains the full step-by-step journey (account → group → face enrollment → camera → background pipeline → distribution → personal gallery), with terminology and UI copy examples to keep consistent. |
| `references/feature-map.md` | Scoping work, breaking a request into tickets, or deciding which module owns a piece of logic. Breaks the product into 10 feature areas with clear ownership boundaries. |
| `references/business-rules.md` | Implementing or reviewing anything touching recognition thresholds, privacy, validation, or distribution. These are the concrete, testable rules — treat them as configuration, never silently change them. |

For most feature work you'll want at least `feature-map.md` (where does this belong) plus
`business-rules.md` (what rules constrain it). For UX/copy work, start with `user-flow.md`.

## Non-negotiables (quick reference)

These four hold across the entire product — full detail in `project-overview.md` and
`business-rules.md`:

1. **Capture never waits on processing.** Capture and background processing are separate
   experiences; a user can fire off shot after shot with zero delay.
2. **Recognition is confidence-based, not "closest match."** A face is only assigned an
   identity when the top score clears ~85% *and* leads the runner-up by ~5–10%. It's always
   better to leave a photo unmatched than deliver it to the wrong person. Thresholds are
   configurable, not hardcoded.
3. **Reference photos are private, permanently.** The face reference captured at join time is
   never visible to other members, never in any gallery, never downloadable by anyone but the
   owner.
4. **Groups are the recognition boundary.** Faces are only ever compared against members of
   the same group the photo was captured in.

If a request would violate one of these, say so explicitly rather than quietly implementing
around it — these are product-level guarantees, not implementation details.
