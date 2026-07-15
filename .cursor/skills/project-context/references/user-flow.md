# Primary User Journey

This is the canonical end-to-end flow. Keep step order, terminology, and the private/public
distinctions below consistent across any screen, API, or copy you design — inconsistency here
is the most common source of confusion between "group photos" and "my private matches."

## Step 1 — Create an account

User authenticates and lands in the main application area. Nothing group-specific happens yet.

## Step 2 — Create or join a group

Two entry points, both leading to a group workspace:

**Create a group** (e.g. `Ritu Wedding`)
The system generates a group identity, group name, a unique join code, and a shareable
invitation. The creator becomes the group owner/administrator.

**Join a group**
1. Enter a group code or open an invitation.
2. See basic group information.
3. Confirm intent to join.
4. Complete the private face reference process (Step 3 below) — this is required, not optional,
   before joining completes.
5. Join the group.

## Step 3 — Private face reference enrollment

Before recognition can work, the user provides a recent, clear reference photo of themselves.
During capture, the user must be told (in the UI, not just in a privacy policy):

- The photo is private.
- Other group members cannot see it.
- It's used only to identify them in group photos.
- A clear, recent photo improves match quality.

**Validation outcomes** the system should detect and surface (ask the user to retake on any
failure — see `business-rules.md` for the full list and handling notes):
- Face clearly detected → proceed
- Face too small
- Multiple faces detected
- Image too dark
- Face partially hidden
- Image too blurry

Goal: a reliable recognition reference without a complicated onboarding. Don't over-engineer
this step with many retries or friction — one clear retake prompt per failure is enough.

## Step 4 — Enter the group

After joining, the user reaches the group workspace, which is the home base for: taking
photos, viewing photos, receiving matched photos, viewing participants, and managing group
settings.

## Step 5 — Open the camera

The camera is opened *from inside* a specific group, and the UI should always make the active
group explicit, e.g. `Capturing for: Ritu Wedding`. This prevents photos from being
misattributed to the wrong event — a real risk for users in multiple simultaneous groups (e.g.
a wedding weekend with both a "Sangeet" and a "Wedding Day" group).

## Step 6 — Capture continuously

The user captures photos back-to-back with zero waiting between shots (Photo 1 → Photo 2 →
Photo 3 …). Each photo enters the processing lifecycle independently the instant it's captured.
See Core Principle 1 in `project-overview.md` — this step is where that principle is most
visible to the user, so it's the easiest place to accidentally violate it (e.g. by blocking the
shutter on an upload call).

## Step 7 — Background processing begins

Conceptual pipeline for each photo:

```
Captured → Saved safely → Prepared for processing → Face detection → Face analysis
→ Identity comparison → Confidence evaluation → Recipient determination → Private distribution
→ Completed
```

The user does not need to stay on the camera screen for any of this.

## Step 8 — Faces are identified

For every detected face in a photo:
1. Analyze the face.
2. Compare against eligible members of *that photo's group only* (Core Principle 4).
3. Rank candidate matches.
4. Apply confidence rules (`business-rules.md`).
5. Accept reliable identities; leave uncertain ones unmatched.

A single photo may contain zero, one, or multiple recognized members, plus any number of
unrecognized people — all of these are valid, common outcomes, not error states.

## Step 9 — Photo is distributed

If a photo contains recognized Person A, Person B, and Person C, it becomes privately available
to: the capturer/uploader, and each of A, B, and C. Model this as **one photo with an access
list**, not as duplicated copies — that keeps storage, edits, and deletion sane and avoids the
four people effectively owning four diverging versions of the same asset.

## Step 10 — Users receive their photos

Each participant has a personal collection — `Photos of Me` — containing every photo across
every group they belong to where they were confidently recognized. This is the payoff moment
of the whole product: the user never went looking for these photos, they simply arrived.
