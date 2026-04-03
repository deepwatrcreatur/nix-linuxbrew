# Start Here

If you are a coding agent starting work in this repo, follow this file and it
should be enough to begin contributing.

## Objective

Pick the next highest-value work item that is not already in progress, do it in
its own branch, and keep the work scoped to one PR.

## Where The Work Queue Lives

Read first:

- [`README.md`](./README.md)
- [`agent-prompts.md`](./agent-prompts.md)

The authoritative work queue is the ordered list in [`README.md`](./README.md).

## How To Choose Work

0. Refresh remote state first if multiple agents may be active (`git fetch origin`).
1. Start with the ordered list in [`README.md`](./README.md).
2. Find the first item whose header says `Status: ready`.
3. Before taking it, check whether the suggested branch/worktree already exists.
4. If a branch/worktree exists but there is no sign of active ownership
   (recent commits, open PR, or file already marked `in-progress`), treat it as
   stale and proceed.
5. Mark the item `in-progress` in your branch as part of the same PR.

## Invariants

- Prefer one focused PR per work item.
- Keep installer/network changes explicit and documented.
- Do not silently widen unsafe defaults just to make activation more convenient.
- Preserve the root-owned vs user-owned module split unless the work item
  explicitly says otherwise.

## PR Workflow

1. Validate locally as appropriate.
2. Push your branch and open a PR.
3. Wait briefly for CI and bot review.
4. Read comments and fix substantive issues.
5. Merge only after checks are green or remaining comments are intentionally
   judged non-blocking.
