# AshAdapter

Swappable adapters for Ash generic actions, in the style of [Knigge](https://hexdocs.pm/knigge).

The resource stays the public API (code interface, `Ash.Error`, tracing). The work behind its
generic actions is done by an adapter module chosen at runtime, e.g. an HTTP client in
production and a Mox mock in tests.

## Installation

```elixir
def deps do
  [
    {:ash_adapter, "~> 0.1.0"}
  ]
end
```

Add `:ash_adapter` to `import_deps` in your `.formatter.exs`.

## Usage

```elixir
defmodule MyApp.Weather do
  use Ash.Resource, domain: MyApp.Domain, extensions: [AshAdapter]

  adapter do
    otp_app :my_app
  end

  actions do
    action :forecast, :string do
      argument :city, :string, allow_nil?: false
      argument :days, :integer, default: 1
    end
  end

  code_interface do
    define :forecast, args: [:city, {:optional, :days}]
  end
end
```

Every generic action without `run` gets dispatched, and the resource gets one callback per
dispatched action. Its arguments come in declaration order; it returns what a `run` would.
The callback is typed from the action, so Hammox checks mocks against it:

```elixir
@callback forecast(city :: String.t(), days :: integer() | nil) :: {:ok, String.t()} | {:error, term()}
```

Built-in Ash types, arrays and `:struct` with `instance_of` get their typespec, `allow_nil?`
adds `| nil`; other types (unions, enums, embedded resources, custom types) become `term()`.

```elixir
defmodule MyApp.Weather.Http do
  @behaviour MyApp.Weather

  @impl true
  def forecast(city, days), do: {:ok, "sunny in #{city} for #{days} days"}
end
```

```elixir
# config/config.exs
config :my_app, MyApp.Weather, MyApp.Weather.Http

# test/test_helper.exs
Mox.defmock(MyApp.WeatherMock, for: MyApp.Weather)
Application.put_env(:my_app, MyApp.Weather, MyApp.WeatherMock)
```

```elixir
MyApp.Weather.forecast!("Berlin")
```

## Options

| Option          | Meaning                                                               |
| --------------- | --------------------------------------------------------------------- |
| `otp_app`       | Application whose env holds the adapter, read on every call.          |
| `config_key`    | Key in the application env. Defaults to the resource module.          |
| `default`       | Adapter used when the application env has none.                       |
| `module`        | Fixed adapter, skips the application env. Excludes `otp_app`.         |
| `pass_context?` | Pass the action context (actor, tenant, …) as last callback argument. |

Without an adapter the action raises.

## Errors

An adapter's `{:error, reason}` reaches the caller as `AshAdapter.Error` with the original
`reason`, inside an `Ash.Error.Unknown`, so callers can still match on it:

```elixir
case MyApp.Weather.forecast("Berlin") do
  {:ok, forecast} -> forecast
  {:error, %Ash.Error.Unknown{errors: [%AshAdapter.Error{reason: :unknown_city}]}} -> "no such city"
  {:error, error} -> raise error
end
```

`AshAdapter.reason/1` takes the reason out of such an error and returns any other error
unchanged, e.g. to keep the plain `{:error, reason}` of a former behaviour:

```elixir
with {:error, error} <- MyApp.Weather.forecast("Berlin"), do: {:error, AshAdapter.reason(error)}
```

Reasons that are already exceptions are passed on to Ash unchanged.

## Verifying adapters

`AshAdapter.resolve/1` returns the adapter currently configured for a resource.
`AshAdapter.verify/1` checks that it is available and exports every callback.
`mix ash_adapter.verify` does this for all resources of the project, e.g. in `.check.exs`:

```elixir
{:ash_adapter, "mix ash_adapter.verify", env: %{"MIX_ENV" => "dev"}}
```

It reads the application env of the current `MIX_ENV`, so mocks defined in `test_helper.exs`
are not visible to it.

## Usage rules for agents

The package ships `usage-rules.md` and the skill `create-ash-adapter` (wrap an external system in
a resource, or add another adapter). Install them with
[usage_rules](https://hexdocs.pm/usage_rules):

```elixir
# mix.exs
def project do
  [
    ...
    usage_rules: [
      file: "AGENTS.md",
      usage_rules: [:ash_adapter],
      skills: [package_skills: [:ash_adapter]]
    ]
  ]
end
```

```bash
mix usage_rules.sync
```
