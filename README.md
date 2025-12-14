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

