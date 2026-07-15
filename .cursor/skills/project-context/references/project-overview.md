# Project Overview — Intelligent Group Photo Sharing Platform

## The Problem

At weddings, trips, parties, college events, corporate events, and family gatherings, many
people take hundreds or thousands of photos — but the people who actually appear in those
photos usually never receive them. Photos stay scattered across individual phones instead of
reaching the people they're of.

## The Solution

A group-based photography and private distribution platform that combines:

- Continuous, interruption-free photo capture
- Event/group-based collaboration
- Private face reference enrollment
- Background photo processing
- Face detection and recognition
- Confidence-based identity matching
- Automatic private photo distribution
- Personal photo collections
- Group photo management

Users create a group for an event — `Ritu Wedding`, `Goa Trip`, `College Farewell`,
`Office Annual Event`, `Family Function` — and others join with a unique group code or
invitation. Once in the group, anyone can capture photos freely; the system figures out,
in the background, who is in each photo and privately delivers it to them.

**The one-line pitch:** *Capture normally. The application automatically handles who should
receive each photo.*

## Core Product Principles

These four principles are non-negotiable and should shape every design and implementation
decision. See `business-rules.md` for the concrete, testable versions of several of these.

### 1. Capture must never be blocked by processing

A user should be able to open the camera, capture a photo, immediately capture another, and
keep going — leaving the camera whenever they're done. They should never wait on image
analysis, face detection, face recognition, uploading, identity matching, or distribution.
**Capture and processing are separate experiences.** Each captured photo enters its own
processing lifecycle independently of the others and independently of whether the user is
still on the camera screen.

### 2. Recognition must be confidence-based, not "closest match"

A detected face is never automatically assigned to whoever it resembles most. A photo is only
distributed to someone when the identity match is *sufficiently reliable* — both a high
absolute similarity score and a meaningful gap over the next-best candidate. The guiding
principle: **it is better to leave a photo unmatched than to privately send it to the wrong
person.** Full thresholds are in `business-rules.md`, and they must stay configurable rather
than hardcoded — recognition quality varies with lighting, camera quality, face angle,
distance, partial visibility, similar-looking people, and changes in appearance over time.

### 3. Reference photos must remain private

The quick photo captured when joining a group is an identity reference, not a social photo —
it is never visible to other members, never appears in any gallery or profile, and can't be
downloaded by anyone else. The UI should always make this distinction clear to the user during
enrollment.

### 4. Groups define the recognition boundary

Face recognition operates within the context of a single group. A photo captured inside
`Ritu Wedding` is only matched against `Ritu Wedding` participants. This keeps the candidate
set small (better accuracy), keeps privacy boundaries clean (you're never matched against
someone else's unrelated event), and keeps photo organization and user expectations simple.

## Where to look next

- Building or reviewing a screen/flow? → `user-flow.md`
- Scoping work or deciding where logic belongs? → `feature-map.md`
- Implementing or checking anything touching thresholds, privacy, or distribution? →
  `business-rules.md`
