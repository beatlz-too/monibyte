---
name: git
description: >
  Manages branches, commits, and push operations using this project's custom emoji-based
  conventional commits. Invoke for any git operation: creating a branch, staging, committing,
  pushing, or understanding the commit message format.
---

# Git Skill

This skill contains the commit message standard and workflow rules for Monibyte. It is copied
verbatim from the Dunchess monorepo (`chateaupixel/gdunchess`, `.agents/skills/git/SKILL.md`) so
that both repos commit in the same language — change it here only when it changes there.

## Custom commit message format

```
ActionEmoji Topic(Subtopic) : [imperative verb] [brief description]
```

Examples:
- `🌟 MapEditor(UI) : add to project`
- `🐞 Pieces(moves) : fix knight's movement bug`
- `✅ Moves(attacks) : refactor moves to be agnostic`
- `📃 Docs(Features) : document moves composability`
- `🧪 Check(moves) : add unit testing`
- `⚡️ Moves(attacks) : add O(n) algorithm to increase speed`

## Emoji → action mapping

| Emoji | Use when |
|-------|----------|
| `🌟` | Adding or significantly extending user-visible behavior or a new internal capability |
| `🐞` | Fixing a bug (behavior was wrong or broken) |
| `🧪` | Primarily changing tests (adding, fixing, refactoring) |
| `📃` | Primarily changing documentation |
| `✅` | Internal cleanup, refactor, CI/config changes, or general maintenance |
| `⚡️` | Performance improvement |

When a change crosses categories, choose the emoji that best describes the **primary intent**.

## Message structure

`ActionEmoji Topic(Subtopic) : [imperative verb] [brief description]`

- **Topic** — short PascalCase topic. Examples: `Rules`, `UI`, `Services`, `Server`, `Docs`, `Godot`, `Multiplayer`.
- **Subtopic** — narrow sub-area in parentheses, optional but recommended.
- **Separator** — always ` : ` (space-colon-space).
- **Imperative verb + brief description** — present tense, no trailing punctuation.

## Workflow

1. Check branch — never commit on `main`.
2. Stage only logically related files; prefer small, focused commits.
3. Draft commit message using the format above.
4. Commit and push once the change set is coherent.
5. Open a PR when the task is complete and pushed.

## Branch naming

`feat/<description>`, `fix/<description>`, `hotfix/<description>`, `release/<version>`, `chore/<description>`, `docs/<description>`.

## Safety rules

- Never push to `main`.
- Never rewrite published history unless explicitly requested.
- Never commit on `main` — always use a task branch.
