# Command Metadata

Read this before adding or changing commands in `bin/`.

Commands in `bin/` can declare CLI metadata in comments near the top of the
file. `bin/agent0s` scans the first 80 lines, and tests expect command metadata
to remain valid.

Supported metadata keys:

- `# agent0s:group=...` - override the command group inferred from the filename
- `# agent0s:name=...` - override the command name inferred from the filename
- `# agent0s:summary=...` - short help text
- `# agent0s:args=...` - usage arguments
- `# agent0s:examples=...` - examples separated with ` | `
- `# agent0s:alias=...` / `# agent0s:aliases=...` - alternate routes
- `# agent0s:hidden=true` - hide from default command listings
- `# agent0s:requires-sudo=true` - mark commands that require sudo

Only use `agent0s:examples` where there are args that need explaining.

Prefer explicit metadata for user-facing commands. Keep routes consistent with
the filename unless there is a deliberate alias or compatibility route.

Example:

```bash
# agent0s:summary=Take a screenshot
# agent0s:args=[smart|region|windows|fullscreen] [slurp|copy]
# agent0s:examples=agent0s screenshot | agent0s capture screenshot region
```
