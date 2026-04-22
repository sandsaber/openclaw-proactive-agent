# working-buffer.md — Danger-Zone Log

**Status:** empty

**Purpose:** once the agent's context reaches 60% full, every subsequent
exchange is appended here verbatim(-ish). The file survives compaction.

**Rules (see SKILL.md / AGENTS.md):**

1. At 60% context: clear the buffer, write `**Started:** <timestamp>`.
2. Append every exchange past that threshold.
3. On compaction / session resume: read this file *first*.
4. Do not ask "where were we?" — the buffer has the conversation.

---

**Started:**  *(empty)*

---

*(exchanges are appended below this line when the danger zone activates)*
