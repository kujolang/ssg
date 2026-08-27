# Release Process

## Current Validated Path

The validated release path for this repo is standard Kujo VM execution.

Use the release gate before shipping changes:

```bash
bash scripts/run_release_gate.sh
```

This gate verifies:

- the version declared in `build.kujo`
- the presence of a matching changelog entry in `CHANGELOG.md`
- the full local CI gate in `scripts/run_ci_checks.sh`
- the deterministic WebMCP config, index, privacy, runtime, layout, and parallel-build contracts
- it does not deploy or publish the site for you

## Release Checklist

1. Update `CHANGELOG.md` for the current `VERSION` in `build.kujo`.
2. Run `bash scripts/run_release_gate.sh`.
3. Review generated output changes if content, templates, or output contracts changed.
4. Push only after the release gate passes cleanly.

## Runtime Note

CI and release validation now execute `kujo run ./build.kujo` directly. If you are debugging a future Kujo regression, compare that VM path against interpreter mode manually, but the release gate no longer depends on `--interpreter`.
