# Kujo Ability integration

SSG publishes three canonical domain definitions and an executable local adapter under `abilities/`: project inspection, generated-output validation, and a guarded build. The adapter is not an embedded network server.

`abilities/runtime.kujo` registers the exact definitions with the commit-pinned Kujo Ability 1.0.1 runtime and supplies direct-argv local handlers. It rejects absolute and escaping output paths, limits process time and captured output, and permits HTTP only for an exact localhost or `127.0.0.1` origin. `site.inspect` and `site.validate` are read effects. `site.build` declares project-read, generated-output-write, and possible network effects; it requires explicit approval and keyed idempotency so a retry cannot silently become a second unrelated build.

Install the dependency with Kennel, then run the offline pack contract:

```bash
kennel validate
kennel install
kujo run tests/ability_pack_tests.kujo --interpreter
KUJO_BIN="$(command -v kujo)" bash scripts/test-ability-pack-integration.sh
```

The fast test initializes all three bindings, executes a read, rejects an escaping path and a spoofed loopback hostname, verifies that build pauses for approval, and checks canonical approval, receipt, and idempotency evidence. The integration wrapper also builds the repository's deterministic starter fixture through the approved Ability binding, validates the generated output, and removes it on exit. CI checks out the exact Ability commit recorded in both `kennel.toml` and `kennel.lock`, so it does not float with the upstream default branch.

The generated static site must not execute these operations. Public WebMCP stays same-origin and read-only. Codex, Cursor, VS Code, Kujo Pi, Agents SDK, and other MCP hosts should connect to a trusted local process or authenticated application gateway that owns identity, authorization, hard timeout and cancellation, receipts, and audit storage.

No publish or deploy Ability is included because this repository does not own a hosting provider. The build handler may fetch configured remote fonts or images, but it receives no deployment credentials. A deployment adapter must declare its external effect, credential boundary, target environment, approval policy, idempotency scope, and rollback evidence before adding that operation.
