# Changelog

All notable changes to this project are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-11-16

Initial release.

### Added

#### `AshAdapter`

- Spark extension that dispatches generic actions without `run` to a swappable, typed adapter.

#### `AshAdapter.Error`

- Wraps an adapter's `{:error, reason}` and keeps the original `reason`.

#### `mix ash_adapter.verify`

- Verifies the configured adapters of all resources in a project.

#### Usage rules

- `usage-rules.md` and the `create-ash-adapter` skill for
  [usage_rules](https://hexdocs.pm/usage_rules).

[0.1.0]: https://github.com/fschoenfeldt/ash_adapter/releases/tag/v0.1.0
