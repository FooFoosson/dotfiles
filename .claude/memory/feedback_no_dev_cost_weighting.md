---
name: feedback-no-dev-cost-weighting
description: "When making technical decisions/recommendations, don't weigh developer effort/cost as a factor"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 063f25f8-f2a7-4133-8c25-a9912af3cf2a
  modified: 2026-08-01T20:56:25.343Z
---

Do not give weight to developer cost (implementation effort, time-to-build, "how much work this is for me/the team") when making technical decisions or recommendations. Choose based on technical merit — correctness, maintainability, performance, security — not how expensive or tedious it is to implement.

**Why:** User explicitly asked that developer cost be excluded from the decision criteria for technical choices.

**How to apply:** When proposing an approach, comparing options, or picking a technical solution, don't cite implementation effort/cost as a reason to favor one path over another. If effort is genuinely relevant to a tradeoff the user needs to know about (e.g. timeline risk), it's fine to mention as a fact, but it should not tip the recommendation.
