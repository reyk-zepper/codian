# Codian Vault Category Guide

Use this to decide where a durable note belongs.

## Decision Tree

```text
Is it tied to a specific project?
+-- yes -> knowledge/projects/
|
+-- no -> Is it a decision with future impact?
          +-- yes -> knowledge/decisions/
          |
          +-- no -> Is it about the user?
                    +-- yes -> knowledge/user-profile/
                    |
                    +-- no -> knowledge/domain/
```

## Defaults

- `projects`: active work, status, milestones, next steps
- `decisions`: rationale, trade-offs, architecture or workflow choices
- `user-profile`: preferences, role, communication style, recurring constraints
- `domain`: reusable technical patterns, research outcomes, proven operating models

## Naming

- Use English ASCII slugs only
- Prefer stable semantic names, not dated session names
- Good: `codian-performance-patterns`
- Bad: `2026-04-12-session-notes`
