# Monibyte

Takes what to test + a task + a project, runs the task N ways, and measures resource spend and result quality for each agentic setup.

## Purpose

Tools often claim big token savings (e.g. [Spotify Shunt](https://gist.github.com/vtri950/84b2261efbadba243870bf161764aeb7)). Monibyte tests claims like these scientifically.

Example:

| Version | Setup |
|---|---|
| A | User's agentic setup as-is |
| B | A + Spotify Shunt |

Designed for **N versions**, not only two.

## Benchmarks

Only three:

| Metric | Source |
|---|---|
| Time | Wall-clock per run, measured by the orchestrator |
| Tokens | CLI's own usage report. Broken down: input / output / cache read / cache write |
| Quality | Pass rate on hidden tests written by the referee |

## Principles

1. **Independence.** Versions never see each other: no shared files, git data, config, or network.
2. **Clean slate.** No run is influenced by previous runs or tests.
3. **Blind tests.** Versions never see the tests. That holds even for TDD experiments, which are scored with metatests.
4. **Assume cheating.** Agents will cheat. Isolation and scoring have to hold up when they try.
5. **Model-agnostic.** Works the same for Claude Code, Codex, etc.
6. **Git projects only.** The target environment has to be a git repo.

## Requirements

| Requirement | Why |
|---|---|
| **Docker** (running locally) | All isolation: one container per run, per scoring pass, and for the referee |
| Git | Snapshot + fresh clones |
| Node 24+ | Runs the orchestrator |
| Credentials for each CLI used (e.g. Anthropic / OpenAI keys or tokens) | Passed into containers as env vars, never via home folders |

## Actors

| Actor | Kind | Job |
|---|---|---|
| Orchestrator | Plain program | Setup, isolation, launching, timing, token collection, running tests, report |
| Builder agent | LLM agent | Turns the subject (e.g. "homemade Spotify Shunt from the open-source material") into a version profile |
| Referee agent | LLM agent | Writes the spec + hidden tests before any run. Optionally does blind subjective judging |
| Version agents | LLM agents | Execute the prompt, one per version per repeat |

The referee does no measuring. Anything that can be deterministic is deterministic.

**Double-blind.** The referee sees only the task + project, never the subject. It can't design tests that favour or punish what's being tested. Version agents never see tests. Builder never sees tests or task results.

## Isolation

Worktrees and branches are **not** used: they share one git database, and sibling folders are visible.

Each run gets:

- **Its own fresh clone** of the starting commit. It contains only that commit and has no link to other runs.
- **Its own container.** It can only see its clone.
- **Its own throwaway home folder**, built from the version's profile: no global CLAUDE.md, memory, skills, MCP servers, or CLI config leaking in. Deleted after the run.
- **Network:** blocked except for the model's API.

Order doesn't matter once runs are isolated. Parallel and sequential runs are equally valid. Sequential gives fairer time numbers (no rate-limit contention).

## Version profile

A version is a declarative profile:

- CLI (Claude Code, Codex, …)
- Model
- Config files, plugins, skills, MCP servers
- Environment variables

Profiles are the only thing that differs between versions.

## Test properties

Set per test:

| Property | Meaning | Default |
|---|---|---|
| `subject` | What's being tested, e.g. "homemade Spotify Shunt from the open-source material". One or more; each becomes a version | required |
| `task` | The work every version does, e.g. "add dark mode" | required |
| `project` | Target git project | required |
| `commit` | Starting commit | current HEAD |
| `baseline` | Version A | Snapshot of the caller's current Claude Code / Codex setup (memory stripped). Can be overridden with any profile(s) from `versions/` if the caller asks |
| `repeats` | Runs per version (K) | **5**, a good sample size and the fallback when unset |

LLM runs vary a lot. Results report the median and spread across `repeats`.

## Flow

0. **Build versions.** Builder agent turns each `subject` into a version profile, layered on the baseline. It has internet access (to fetch source material); runs don't. Profiles are frozen (hashed) before any run. No human approval step; the report shows exactly what was built.
1. **Setup.** Orchestrator snapshots `project` at `commit` and loads baseline + built profiles. Project environment comes from the project's own Dockerfile/devcontainer; if it has neither, the referee writes one. Every run and every scoring pass uses that same environment.
2. **Spec + tests.** The referee writes:
   - a short **spec** (names, inputs, outputs), added to the prompt identically for every version
   - **hidden tests** (+ metatests if needed), sealed by hash and stored outside every version's reach.
3. **Runs.** N versions × K repeats, each isolated as above. Orchestrator records time + tokens.
4. **Scoring.** Each run's output is copied into a fresh scoring environment. The sealed tests are added on top, overwriting anything the version planted, and then run.
5. **Optional blind judging.** Referee scores subjective quality with versions anonymized and shuffled.
6. **Report.** Per version: median + spread for time, tokens (broken down), and test pass rate.

## CLI adapters

One small adapter per supported CLI. Each one:

- launches the CLI headless with the prompt
- reads the CLI's own usage output (e.g. Claude Code JSON output, `codex exec --json`)
- returns time + token breakdown in a common format

## Usage

End-to-end is always **subject + task + project → results**.

```
cd monibyte
/run-test "Make a homemade version of Spotify Shunt using the open-source material, then test ../my-app by adding dark mode"
```

The kickoff session splits the sentence into `subject`, `task`, `project`, and each one appears in the report.

Works the same for a person or an automated caller. Results land in `results/<run-id>/report.md`.

The session you type `/run-test` in only kicks things off. It is **not** the referee. The referee runs in its own clean container, so your own setup can't bias it.

## Stack

| Piece | Choice | Why |
|---|---|---|
| Entry point | Skill `run-test`, shipped in the repo for Claude Code and Codex | Matches the `/run-test` usage; model-agnostic |
| Orchestrator | TypeScript on Node 24, no build step | Runs `.ts` directly; one language for everything |
| Isolation | Docker: one image per CLI + an egress proxy that only allows model APIs | Enforces the network rule |
| Referee | Fixed referee profile, in its own container | Same impartial referee every time |
| Report | Markdown + raw JSON per run | Readable by people and machines |

## Repo layout

| Folder | Holds |
|---|---|
| `.claude/skills/run-test/`, `.agents/skills/run-test/` | The `/run-test` skill (Claude Code / Codex) |
| `versions/<name>/` | Baseline + built profiles, one per folder: CLI, model, home-folder overlay (CLAUDE.md, settings, skills, MCP) |
| `referee/` | The referee's profile + instructions |
| `orchestrator/` | The program |
| `docker/` | Images + egress proxy |
| `results/<run-id>/` | Report, raw per-run data, sealed tests (git-ignored) |

## Build plan

| # | Step | Done when |
|---|---|---|
| 1 ✅ | Docker images + egress proxy | A container reaches the model API but not any other site. Allowlist: `docker/proxy/allowlist.txt`. Check: `docker/verify-network.sh` |
| 2 | Claude Code adapter | A toy prompt returns time + token breakdown |
| 2b | Builder: subject → profile | "Homemade Shunt" produces a frozen profile that loads in a container |
| 3 | Orchestrator: snapshot, clones, N × K runs | 2 versions × 2 repeats on a toy repo, fully isolated |
| 4 | Referee: spec + sealed tests | Tests exist before any run; the hash matches at scoring |
| 5 | Scoring | Hidden tests overwrite planted files; pass rates recorded |
| 6 | Report | Median + spread per version |
| 7 | `/run-test` skill | One command, prompt + project → report |
| 8 | Codex adapter | Same toy run works with Codex |

## Decisions

| Topic | Decision |
|---|---|
| Isolation runtime | Local Docker |
| Repeats | 5 by default, configurable per test |
| Baseline | Caller's current setup by default; any `versions/` profiles if asked |
| Built versions | Automatic, no approval pause; shown in report |
| Project toolchain | Project's Dockerfile/devcontainer, else referee writes one |
