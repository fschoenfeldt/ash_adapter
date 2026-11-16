# AshAdapter

Spark extension for Ash resources: generic actions without `run` are dispatched to a swappable
adapter module, and the resource becomes the behaviour of that adapter. Keep it a lean library:
no runtime dependencies besides `ash` and `spark`.

## Layout

- `lib/ash_adapter.ex` – the extension: `adapter` section (DSL schema), `resolve/1`, `verify/1`.
- `lib/ash_adapter/transformer.ex` – sets `run {AshAdapter.Dispatch, …}` on every generic action
  without `run`, evaluates one `@callback` per dispatched action into the resource, persists
  `:ash_adapter_source` and `:ash_adapter_callbacks`, validates `otp_app` xor `module`.
- `lib/ash_adapter/dispatch.ex` – `Ash.Resource.Actions.Implementation` that resolves the adapter
  and calls it with the arguments in declaration order (plus context with `pass_context?`);
  wraps a returned `{:error, reason}` in `AshAdapter.Error`.
- `lib/ash_adapter/error.ex` – `AshAdapter.Error` (class `:unknown`), keeps the adapter's `reason`.
- `lib/ash_adapter/typespec.ex` – Ash type → quoted typespec; unknown types become `term()`.
- `lib/mix/tasks/ash_adapter.verify.ex` – `mix ash_adapter.verify` over all resources of the app.
- `usage-rules.md`, `usage-rules/skills/` – rules and skills shipped to consumers via `usage_rules`.

## Rules

- Public API and behaviour changes update `README.md`, `usage-rules.md` and the skill
  `usage-rules/skills/create-ash-adapter/SKILL.md` in the same change.
- New DSL options go into the schema in `lib/ash_adapter.ex` and into `dsl_options` in
  `.formatter.exs` (exported as `locals_without_parens`).
- No function in `AshAdapter` may share a name/arity with a DSL section macro: Spark defines
  `adapter/1` there, which is why the lookup is `resolve/1`.
- Don't put module attributes before `use Spark.Dsl.Extension` – Quokka moves `use` to the top
  and rewrites them into `unquote` fragments. Inline the section instead.
- The transformer reads options with `Spark.Dsl.Transformer`; resolve modules only at runtime
  (dispatch, verify), never at compile time, to avoid compile-time dependencies on adapters.
- Configuration in `config/config.exs` is only for this library's tests; consumers don't load it.

## Tests

- Test resources and adapters live in `test/support/resources.ex` (compiled in `:test` only);
  the Mox mock for `AshAdapter.Test.Weather` is defined in `test/test_helper.exs`.
- One test file per module (`test/ash_adapter_test.exs`, `test/ash_adapter/<module>_test.exs`,
  `test/mix/tasks/<task>_test.exs`).
- Generated callbacks are asserted as typespec strings via `Code.Typespec.fetch_callbacks/1`.

## Quality bar

- After changing any `.ex`/`.exs` file run `mix check --fix --format agent` and make it pass
  (compiler, credo, dialyzer, ex_doc, ex_unit, formatter with Quokka, hex_audit, unused_deps).
- CI (`.github/workflows/ci.yml`) runs `mix check --format github` with `MIX_ENV=test`, versions
  from `.tool-versions`.
