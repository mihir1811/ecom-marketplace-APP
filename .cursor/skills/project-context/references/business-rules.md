# Business Rules

Concrete, testable rules. Anything in this file should be treated as configuration to expose
and reason about explicitly in code and QA — not a constant to bury inline or a nuance to
paraphrase away. When a request would contradict one of these, flag it rather than quietly
implementing the contradiction.

## Recognition confidence rule

A face is only confidently assigned an identity when **both** of these hold:

1. The highest similarity score is greater than **~85%**.
2. The gap between the highest and second-highest score is **~5–10%** or more.

**Example — confidently matched:**
| Candidate | Similarity |
|---|---|
| Person A | 92% |
| Person B | 78% |
| Person C | 61% |

Person A clears 85% and has a 14-point gap over Person B → confidently identified.

**Example — left unmatched:**
| Candidate | Similarity |
|---|---|
| Person A | 89% |
| Person B | 86% |
| Person C | 62% |

Person A clears 85%, but the gap to Person B is only 3 points → too close to call, so the
face is **not** assigned to anyone, even though Person A is the top score.

**Configurability:** both numbers (85% floor, 5–10% gap) are defaults, not hardcoded
constants. Recognition quality shifts with lighting, camera quality, face angle, distance,
partial visibility, similar-looking people, and a person's appearance changing over time — the
thresholds must be adjustable (ideally per-group or globally, via config) without a code
change.

**Guiding principle:** it is always better to leave a photo unmatched than to privately
distribute it to the wrong person. When in doubt about a new matching feature or edge case,
resolve it in favor of *not* matching.

## Reference photo privacy rules

The private face reference captured at group join time is an identity reference, not a social
photo. Concretely:

- Not viewable by other group members, under any permission level (including group owner/admin).
- Never appears in the group gallery.
- Never appears on the user's public profile.
- Not downloadable by other participants.
- Never auto-shared or included in exports, backups shared with others, or notifications.
- Accessible only to the owning user (where the product chooses to let them view/retake it)
  and to the recognition system itself.

Treat this as a distinct access-control path from group-photo permissions, not a special case
of the same one — the two should be hard to accidentally conflate in code.

## Reference photo validation rules

Before enrollment completes, validate the captured reference and require a retake on any
failure. Recognized outcomes:

- Face clearly detected → pass
- Face too small → retake, ask user to move closer
- Multiple faces detected → retake, ask for a solo photo
- Image too dark → retake, ask for better lighting
- Face partially hidden → retake, ask to uncover face
- Image too blurry → retake, ask to hold steady / refocus

Keep this a single clear retake prompt per failure — the goal is a reliable reference without
turning onboarding into a multi-step ordeal.

## Group recognition boundary rule

Recognition candidate sets are scoped to a single group. A face detected in a photo captured
inside `Ritu Wedding` is compared only against `Ritu Wedding` participants — never against the
user's full account graph or other groups they belong to. This is both an accuracy rule
(smaller, more relevant candidate set) and a privacy rule (no cross-event matching).

## Distribution / access rule

When a photo is confidently matched to one or more people, model it as **one photo with an
access list**, not as separate copies per recipient:

- Authorized viewers = the capturer/uploader + every confidently matched person.
- The underlying asset stays singular — edits, deletion, or moderation apply once, not once
  per recipient.
- A photo with zero confident matches still exists in the group gallery; it simply isn't added
  to anyone's personal `Photos of Me` feed until/unless a later match is made.

## Capture-blocking rule

No user-facing feature may make photo capture wait on: image analysis, face detection, face
recognition, uploading, identity matching, or distribution. If a proposed feature needs to
show the user something derived from processing (e.g. "3 people matched") synchronously during
capture, it violates this rule — surface it later, asynchronously, instead.
