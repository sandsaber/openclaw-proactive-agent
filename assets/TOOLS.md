# TOOLS.md — Tool Configuration

**Rule:** this file stores **tool descriptions, gotchas, and allowlist
pointers**. It does NOT store secrets, tokens, keys, credentials, or
environment variable values. Secrets live in a runtime-provided secret
store and are referenced by name, never by value.

**Write-access:** Tier 1 (logged) for everything *except* any field whose
name contains "token," "secret," "key," "password," "credential" — those
are Tier 2 and must be stored outside this file anyway.

---

## Tool inventory

For each tool the agent may use, describe:

### <tool-name>

- **Purpose:**
- **Tier for typical use:** 0 | 1 | 2
- **Inputs:**
- **Side-effects:**
- **Gotchas the agent has learned:**
- **Secrets required:** `[runtime secret ref: <name>]` — never the value
- **Rate limits / etiquette:**
- **Last used:** [YYYY-MM-DD]

---

## Tool categories and default tiers

| Category | Examples | Default tier |
|----------|----------|-------------|
| File read (inside workspace) | Read, Grep, Glob | 0 |
| File write (operating files) | Edit, Write to `AGENTS.md` etc. | 1 |
| File write (locked files) | Write to `POLICY.md`, `SOUL.md`, `SKILL.md` | 2 |
| Shell read-only | `ls`, `git status`, `cat` | 1 |
| Shell destructive | `rm`, `mv` outside workspace, `chmod -x` on scripts | 2 |
| Network outbound | `curl`, `wget`, API calls, MCP network tools | 2 |
| Package install | `pip`, `npm`, `brew`, `apt` | 2 |
| Git read-only | `git log`, `git diff`, `git blame` | 1 |
| Git write (local) | `git add`, `git commit` | 1 |
| Git write (remote) | `git push`, `git tag push` | 2 |
| Messaging | email, Slack, Discord, DMs | 2 |
| Sub-agent (read-only) | isolated agent without network | 1 |
| Sub-agent (write/net) | isolated agent with any elevated privilege | 2 |

If a tool is not listed, the default is Tier 2. Promote explicitly after
review.

---

## Prohibited tools

*(tools the agent refuses to use even with approval)*

- Anything that connects to agent-to-agent networks or agent directories.
- Anything that registers this agent with an external service.
- Anything that modifies `POLICY.md` or `SOUL.md` mechanically.

---

## Secret handling

- Secrets are referenced by name only: `SECRET_REF[stripe-prod]`.
- The agent **never prints a secret value** to any log, file, or
  response, even if it was loaded into memory.
- If a secret appears in tool output (e.g., an API response echoing a
  token), the agent redacts before writing to `AUDIT-LOG.md` or
  `memory/*`.
- The agent never copies `.env`, `.credentials/`, `.aws/`, `.kube/`,
  `.ssh/`, or any dotfile containing auth material.
- If the human explicitly shares a secret in a message ("here's the
  token: …"), the agent must immediately propose redaction of the
  message from persistent memory and ask the human to rotate.
