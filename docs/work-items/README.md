# Work Items

Start here if you are assigning another agent:

- [`START-HERE.md`](./START-HERE.md)

This folder is the working queue for `nix-linuxbrew` follow-up.

Use this instead of one large planning note when multiple agents may work in
parallel on separate branches.

## How To Use

- Treat each file in this folder as one PR-sized work stream.
- Prefer one agent per file/branch.
- Mark the file as `in-progress` in its header once an agent starts it.
- When work is fully merged, either delete the file or keep it briefly as
  `done` if it records useful outcome notes for follow-up agents.
- `done` items must not remain in the active ranking; archive or delete them
  once their notes are no longer useful.
- If the work changes shape materially, update the file instead of creating
  drift only in chat.

## Current Ranked Queue

1. `01-installer-reproducibility-controls.md`
2. `02-dry-run-and-plan-mode.md`
3. `03-failure-reporting-and-strict-mode.md`
4. `04-option-schema-tightening.md`
5. `05-ci-and-static-checks.md`
6. `06-wrapper-deduplication.md`
7. `07-multi-user-guidance-and-defaults.md`
8. `08-maintenance-ergonomics.md`

## Why This Structure

Small files work better than one large roadmap because they:

- reduce context loading for follow-up agents
- make ownership clearer
- map cleanly to one branch / one PR
- are easy to delete once merged
