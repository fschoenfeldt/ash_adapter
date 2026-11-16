---
name: create-ash-adapter
description: "Use when wrapping an external system (HTTP API, library, legacy module) behind a swappable Ash resource with AshAdapter, or when adding another adapter (e.g. a fake, a second backend) to an existing resource that uses `extensions: [AshAdapter]`."
---

# Create an AshAdapter resource or adapter

First decide which case applies:

- **New resource**: no resource for the external system exists yet → steps 1–5.
- **New adapter for an existing resource**: the resource already has an `adapter` section → steps 3–5.

Read the resource's existing actions and callers before changing anything.

## 1. Resource

Create the resource next to its domain. Model each operation as a generic action; arguments are
the inputs, the return type is the result. Prefer precise Ash types: they become the callback
typespecs.

```elixir
defmodule MyApp.Weather do
  use Ash.Resource, domain: MyApp.Domain, extensions: [AshAdapter]

  adapter do
    otp_app :my_app
  end

  actions do
    action :forecast, :string do
      description "Forecast for a city."
      argument :city, :string, allow_nil?: false
      argument :days, :integer, default: 1
    end
  end

  code_interface do
    define :forecast, args: [:city, {:optional, :days}]
  end
end
```

- `otp_app` for adapters that differ per environment, `module` for a single fixed adapter.
- Add `pass_context? true` only if the adapter needs actor or tenant.
- Register the resource in its domain unless the domain allows unregistered resources.

## 2. Configuration

```elixir
# config/config.exs
config :my_app, MyApp.Weather, MyApp.Weather.Http
```

Without config and without `default`, the action raises.

## 3. Adapter

One module per backend, named after it (`MyApp.Weather.Http`, `MyApp.Weather.Fake`):

```elixir
defmodule MyApp.Weather.Http do
  @behaviour MyApp.Weather

  @impl true
  def forecast(city, days) do
    # call the external system, map its result and errors
    {:ok, "sunny in #{city} for #{days} days"}
  end
end
```

- One function per dispatched action, arguments in the action's declaration order.
- Return `{:ok, value} | {:error, reason}`, or `:ok | {:error, reason}` without return type.
- Map external errors to `{:error, reason}`; don't raise for expected failures. Callers get the
  `reason` back as `%AshAdapter.Error{reason: reason}` inside an `Ash.Error.Unknown`.
- Outcomes other than `{:ok, _}`/`{:error, _}` (e.g. `{:warning, _}`) belong into the value.
- To switch environments, point the config (e.g. `config/dev.exs`) at the new adapter.

## 4. Tests

```elixir
# test/test_helper.exs
Mox.defmock(MyApp.WeatherMock, for: MyApp.Weather)
Application.put_env(:my_app, MyApp.Weather, MyApp.WeatherMock)
```

- Callers: test through the code interface with `expect(MyApp.WeatherMock, :forecast, fn city, days -> … end)`.
- Adapter: test the adapter module directly against the external system's test double.

## 5. Verify

```bash
MIX_ENV=dev mix ash_adapter.verify
```

It must list no resource. Then run the project's test suite.
