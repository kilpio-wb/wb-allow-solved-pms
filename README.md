# Discourse Solved in Group Messages (PMs)

Re-enables the **“Mark as Solution”** feature inside **private messages** in Discourse—primarily for **group inbox / support mailbox** workflows.

This is intended for setups where incoming support emails are turned into Discourse PMs, staff replies go back out via email, and staff want to mark a reply as the solution inside that PM thread.

> Note: Upstream removed/disabled accepting solutions in PMs. This plugin intentionally restores that behavior with configurable restrictions.

---

## What it does

- Restores the ability to **accept/unaccept an answer** in PM topics.
- By default, it is designed to work **only for group-message PMs** (messages addressed to one of the configured groups, e.g. `support`).
- Lets you restrict:
  - **Which PM topics are eligible** (`solved_pm_target_groups`)
  - **Who can mark/unmark solutions** (`solved_pm_actor_groups`, `solved_pm_allow_topic_owner`)
  - Whether to allow **1:1 DMs** (`solved_pm_allow_personal_messages`)

---

## Compatibility

- Targeted at **Discourse 2025.11.x** (where Solved is bundled into core).
- The plugin patches `Guardian#can_accept_answer?`. If Discourse changes that method signature/name in the future, the plugin may need a small update.

---

## Settings

Go to **Admin → Settings** and search for `solved_pm`.

These settings control where the **Solved** feature is available in **private messages** and who can use it.

### `solved_pm_enabled` — Enable Solved in private messages
Master switch for this plugin.

- **On**: The plugin may allow “Mark as Solution” in private messages (subject to the rules below).
- **Off**: The plugin does nothing; PMs behave like stock Discourse (no solutions in PMs).

> Note: `solved_enabled` (core Solved setting) must also be enabled.

---

### `solved_pm_target_groups` — PM target groups eligible for Solved
Restricts *which PM topics* are eligible.

- If **set to one or more groups** (recommended), solutions are allowed **only** in PMs that include at least one of these groups as a recipient (i.e., **group inbox** messages).
  - Example: `support|support_lvl2`
- If **left empty**, eligibility depends on `solved_pm_allow_personal_messages`:
  - Group inbox PMs may still be eligible.
  - 1:1 PMs become eligible only if `solved_pm_allow_personal_messages` is enabled (see below).

**Recommended for support-mailbox workflows:** set this to your support group (e.g. `support`) to avoid enabling solutions in personal DMs site-wide.

---

### `solved_pm_actor_groups` — Groups allowed to mark solutions in eligible PMs
Restricts *who can mark/unmark* solutions inside eligible PM topics.

- Members of the listed groups can mark/unmark solutions.
- **Staff** can always mark/unmark solutions regardless of this setting.

Example: `staff|support_agents`

> If this is empty, only staff (and optionally the topic owner, depending on `solved_pm_allow_topic_owner`) can mark solutions.

---

### `solved_pm_allow_topic_owner` — Allow PM topic owner to mark a solution
Controls whether the **PM topic owner** (the user who started the PM) is allowed to mark/unmark a solution.

- **On**: The PM topic owner can mark/unmark solutions (in eligible PMs).
- **Off**: Only staff / allowed actor groups can mark/unmark solutions.

**Common support configuration:** set this **Off** if you don’t want customers to mark solutions.

---

### `solved_pm_allow_personal_messages` — Allow Solved in 1:1 private messages
Controls whether solutions can appear in **1:1 DMs** (personal private messages between two users).

- **Off** (recommended): solutions are **not** available in 1:1 DMs.
- **On**: solutions can be available in 1:1 DMs *if other eligibility rules allow it* (especially relevant when `solved_pm_target_groups` is empty).

**Recommended:** keep this **Off** unless you explicitly want solution-marking in personal DMs.

---

## Recommended configurations

### Support mailbox (group inbox) only
- `solved_pm_enabled` = ✅
- `solved_pm_target_groups` = `support`
- `solved_pm_actor_groups` = `staff|support_agents` (or just `staff`)
- `solved_pm_allow_topic_owner` = ❌ (optional but common)
- `solved_pm_allow_personal_messages` = ❌

### Allow solutions in 1:1 DMs (site-wide)
- `solved_pm_enabled` = ✅
- `solved_pm_target_groups` = *(empty)*
- `solved_pm_actor_groups` = `staff` (or add more groups if desired)
- `solved_pm_allow_topic_owner` = ✅/❌ (your choice)
- `solved_pm_allow_personal_messages` = ✅


---

## Installation (Discourse Docker)

### 1) Add the plugin to your `app.yml`

Edit:

- `/var/discourse/containers/app.yml`

Add a `git clone` under `hooks: after_code:`:

```yml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/your-org/wb-allow-solved-pms.git

