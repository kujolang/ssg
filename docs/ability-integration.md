# Kujo Ability integration

SSG publishes three canonical domain definitions under `abilities/`: project inspection, generated-output validation, and a guarded build. They are producer contracts, not an embedded network server.

An application or local agent adapter registers the exact definitions with Kujo Ability 1.0.1, supplies handlers, restricts every input and output path to the trusted project root, and exposes only the surfaces it intends to support. `site.inspect` and `site.validate` are read effects. `site.build` declares a write effect, requires explicit approval, and uses keyed idempotency so a retry cannot silently become a second unrelated build.

The generated static site must not execute these operations. Public WebMCP stays same-origin and read-only. Codex, Cursor, VS Code, Kujo Pi, Agents SDK, and other MCP hosts should connect to a trusted local process or authenticated application gateway that owns identity, authorization, hard timeout and cancellation, receipts, and audit storage.

No publish or deploy Ability is included because this repository does not own a hosting provider. A deployment adapter must declare its external effect, credential boundary, target environment, approval policy, idempotency scope, and rollback evidence before adding that operation.
