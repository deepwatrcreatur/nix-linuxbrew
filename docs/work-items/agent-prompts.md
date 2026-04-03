# Agent Prompts

Use these prompts to dispatch other agents onto the queue.

## Prompt 1

Read [`docs/work-items/START-HERE.md`](./START-HERE.md) and take the
highest-priority item still marked `Status: \`ready\``. Keep the work to one
PR and update the item status in your branch.

## Prompt 2

Implement [`01-installer-reproducibility-controls.md`](./01-installer-reproducibility-controls.md).
Add explicit installer source controls and optional hash verification without
breaking the current default behavior for existing users.

## Prompt 3

Implement [`02-dry-run-and-plan-mode.md`](./02-dry-run-and-plan-mode.md).
Add a safe plan mode that prints the exact `brew` actions that would run
without mutating state.

## Prompt 4

Implement [`03-failure-reporting-and-strict-mode.md`](./03-failure-reporting-and-strict-mode.md).
Improve observability for partial failures and add an opt-in strict mode for
package operation errors.
