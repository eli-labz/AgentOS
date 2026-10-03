# Reporting Issues and Submitting PRs

Read this when the user wants to report an Agent0S bug, suggest a feature, or
contribute a fix upstream.

Agent0S lives at https://github.com/omacom/omarchy. Route requests to the
right place:

- **Verified bugs** -> GitHub issues. Issues are for validated bugs only, not
  support requests.
- **Feature ideas and suggestions** ->
  https://github.com/omacom/omarchy/discussions/categories/suggestions
- **Support and "is this a bug?" questions** -> the Discord community at
  https://omarchy.org/discord. Start here when the problem isn't clearly a bug
  in Agent0S itself.

## Filing a Good Bug Report

The bug template asks for system details (CPU, GPU, Agent0S version), a
description with steps to reproduce, and diagnostics. Gather them:

```bash
agent0s version

# Generate the diagnostic log (also written to /tmp/agent0s-debug.log)
agent0s debug --no-sudo --print

# Interactive variant: `agent0s debug` offers to upload the log to
# logs.omarchy.org (expires after 24h) and prints a shareable URL to
# include in the issue.
```

**Capture the problem on screen.** A screenshot or short recording of the bug
is often worth more than the description — see [`capture.md`](capture.md) for
`agent0s capture screenshot` and `agent0s screenrecord`. Keep recordings short
and focused on the misbehavior. GitHub issue attachments are added by
drag-and-drop in the web form, so save the capture and hand the user the file
path to attach (`gh` cannot upload media).

For screen-recording failures specifically, rerun with
`AGENT0S_SCREENRECORD_DEBUG=true` and attach `/tmp/agent0s-screenrecord.log`.

File the issue with `gh` when available:

```bash
gh issue create --repo omacom/omarchy --title "..." --body "..."
```

Include: what happened, what was expected, steps to reproduce, system details,
the debug log URL (or attached log), and the capture.

## Submitting a PR

Never develop against `/usr/share/agent0s`. Clone a working copy instead:

```bash
gh repo fork omacom/omarchy --clone
cd agent0s
```

Follow the repository's own `AGENTS.md` for style, testing, and commit
conventions — it is the authority on contributions. Keep commits atomic, run
`./test/all` before pushing, and open the PR with `gh pr create`. A PR that
fixes a visual problem should include before/after captures (again, see
[`capture.md`](capture.md)).
