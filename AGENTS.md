# Agent Instructions

This repository contains reusable AI agents and Agent Skills for specialized workflows, Flutter development, and project context.

## CRITICAL: MINIMAL OUTPUT POLICY

Your primary job is to execute tasks, not narrate them.

Unless explicitly requested by the user:
- DO NOT explain code.
- DO NOT explain your reasoning.
- DO NOT announce planned actions.
- DO NOT provide progress commentary.
- DO NOT provide implementation walkthroughs.
- DO NOT generate verbose summaries.
- DO NOT repeat information already visible in the code or task.

Work silently and return only a concise final result.

This communication policy applies to every task and takes priority over default conversational verbosity.

## AI Environment Directories

Use only the agents and skills native to the currently active environment:

| Environment | Agents | Skills |
|---|---|---|
| GitHub / VS Code | `.github/agents/` | `.github/skills/` |
| Agent Skills Compatible | `.agents/agents/` | `.agents/skills/` |
| OpenCode | `.opencode/agents/` | `.opencode/skills/` |
| Cursor | `.cursor/agents/` | `.cursor/skills/` |

Equivalent agents and skills may exist in multiple directories for compatibility.

**Never load duplicate copies from other environments.**

---

## Agents

The active environment's `agents/` directory contains specialized agents for specific roles, tasks, and workflows.

Before performing a task:

1. Check whether a relevant specialized agent exists.
2. Use it when its purpose matches the task.
3. Do not invoke unrelated or unnecessary agents.
4. Use the minimum number of agents required.

Agents define **who performs the task and how it is approached**.

---

## Skills

The active environment's `skills/` directory contains reusable Agent Skills.

A skill may contain:

- `SKILL.md` — skill entry point
- `references/` — supporting knowledge

Treat the entire skill directory as part of the skill.

When using a skill:

1. Read its `SKILL.md`.
2. Follow referenced files when relevant.
3. Load only the references required for the current task.
4. Use scripts and assets only when needed.
5. Preserve relative paths.
6. Never load all skills or references automatically.

Skills provide **reusable knowledge, instructions, workflows, and resources**.

---

# Available Skills

## `flutter-production-builder`

Provides production-ready Flutter development guidance for scalable, modular, maintainable, reliable, and high-quality applications.

Use for:

- Feature and module development
- UI and reusable widgets
- State management
- API integration
- Navigation and data handling
- Architecture and project structure
- Error handling
- Performance and scalability
- Major Flutter refactoring
- Production-quality implementation

## `project-context`

Provides high-level project understanding, including:

- Project purpose and overview
- Application and user flows
- Feature and module relationships
- Business context and product behavior
- System-wide requirements

Use this skill only when broader product understanding is necessary.

### Load `project-context` for:

- New features or modules
- New functionality
- Major behavioral or functional changes
- User-flow or workflow changes
- Cross-feature or multi-module changes
- System-wide changes
- Major architectural decisions dependent on product requirements

### Do not load `project-context` by default for:

- Bug or error fixing
- Debugging
- Build, compilation, dependency, or configuration errors
- Code review
- Testing existing behavior or fixing tests
- Linting or formatting
- Small localized changes
- Minor UI fixes
- Behavior-preserving refactoring
- Localized cleanup or optimization

For these tasks, prefer relevant code, local module context, logs, errors, stack traces, and tests.

Load only the relevant parts of `project-context` as an exception when product behavior or business rules are necessary to complete the task correctly.

---

# Task Workflow

Classify the task before loading agents, skills, or large context.

## New Feature, New Module, or Major Change

1. Use a relevant specialized agent if available.
2. Load `project-context` and only the references relevant to the requested change.
3. Load `flutter-production-builder` and only the references relevant to implementation.
4. Inspect the existing codebase, architecture, patterns, and reusable components.
5. Plan, implement, and validate the change.

**Flow:**

`relevant agent → project-context → flutter-production-builder → existing codebase → implementation → validation`

## Standard Flutter Development

1. Use a relevant specialized agent if available.
2. Load `flutter-production-builder`.
3. Do not load `project-context` unless broader product understanding is required.
4. Inspect relevant existing code and follow established patterns.
5. Implement and validate the work.

**Flow:**

`relevant agent → flutter-production-builder → relevant codebase → implementation → validation`

## Bug Fixing and Debugging

1. Do not load `project-context` by default.
2. Inspect the error, logs, stack traces, failing behavior, and relevant code.
3. Identify the root cause before modifying code.
4. Use a relevant specialized agent or skill only when needed.
5. Make the smallest correct fix and validate against regressions.

**Flow:**

`bug/error → local diagnostics and code → relevant agent/skill if needed → root-cause fix → validation`

## Code Review

1. Do not load `project-context` by default.
2. Inspect the code under review and directly related code.
3. Use a code-review agent or `flutter-production-builder` only when relevant.
4. Report concrete findings without loading unrelated project context.

## Testing

1. Do not load `project-context` by default.
2. Inspect the implementation, existing tests, and testing conventions.
3. Use a testing agent or relevant skill only when needed.
4. Test existing behavior and validate the results.

Load project context only when expected behavior cannot be determined from the task, implementation, tests, or local documentation.

---

# Context Efficiency

Use progressive disclosure and the minimum context required to complete the task correctly.

- Use only the active environment's agents and skills.
- Never load duplicate copies from other environment directories.
- Load only relevant agents, skills, and reference files.
- Do not load the entire project context for localized work.
- Prefer existing code and local module context when sufficient.
- Prefer logs and stack traces for debugging.
- Prefer existing tests for established behavior.
- Expand context only when necessary for correctness.

## Core Principle

Use the minimum necessary combination of:

`specialized agent + relevant skills + required project context + relevant codebase context`

For new features and major changes, understand the relevant project context before implementation.

For bugs, errors, reviews, tests, and localized changes, work from local context first and load broader context only when genuinely required.