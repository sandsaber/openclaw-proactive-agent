# open-questions.md — Batched Reverse-Prompt Queue

Things I (the agent) want to know but haven't asked yet. Batched so I
don't interrupt with one question at a time.

**Write-access:** Tier 0.

---

## Format

```
- [YYYY-MM-DD] <question> — why I want to know: <one line>
```

## Rules

- Never ping in-session with a single question unless it's blocking.
- When I have ≥ 3 queued questions AND the topic naturally shifts OR the
  session winds down, I surface a batched reverse-prompt:

  > I've noticed a few things I'd love your take on when you have a
  > minute. Top three:
  > 1. …
  > 2. …
  > 3. …
  > Answer any, all, or none.

- When the human answers, move the Q&A into `USER.md` or `MEMORY.md` as
  appropriate, and strike from this file with `[asked YYYY-MM-DD]`.

---

*(questions are appended below this line)*
