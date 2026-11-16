# Rules for working with AshAdapter

## Understanding AshAdapter

AshAdapter makes the generic actions of an Ash resource swappable. The resource is the public
API and the behaviour; an adapter module does the work. Use it to wrap external systems (HTTP
APIs, other libraries, legacy code) behind a resource, with a real adapter in production and a
mock in tests.

## Declaring the resource

- Add `extensions: [AshAdapter]` and an `adapter` section with either `otp_app` or `module`, never both.
- Every generic action (`action :name, :return_type`) without `run` is dispatched to the adapter.
  Actions with their own `run`, and create/read/update/destroy actions, are untouched.
- Call the actions only through the code interface or `Ash.run_action/2`, never the adapter directly.

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

Options of the `adapter` section:

- `otp_app` – application whose env holds the adapter, read on every call: `config :my_app, MyApp.Weather, MyApp.Weather.Http`.
- `config_key` – key in the application env, defaults to the resource module.
- `default` – adapter when the application env has none.
- `module` – fixed adapter, no application env.
- `pass_context?` – append the `Ash.Resource.Actions.Implementation.Context` (actor, tenant, …) as last argument.

## Writing an adapter

- The resource is the behaviour: `@behaviour MyApp.Weather` and `@impl true` on every callback.
- One function per dispatched action, named like the action, taking the arguments in
  declaration order (plus the context with `pass_context?`).
- Return `{:ok, value}` or `{:error, reason}`; actions without return type return `:ok` or `{:error, reason}`.
- The caller gets `{:error, %Ash.Error.Unknown{errors: [%AshAdapter.Error{reason: reason}]}}`; match on
  `reason` there instead of parsing the error message. Exception reasons are passed on unchanged.
- A generic action can't return anything else (e.g. `{:warning, _}`): model such outcomes as part of the value.
- Callbacks are typed from the action (`String.t()`, `integer() | nil`, …); keep the adapter's
  `@spec`s in line, Hammox checks mocks against them. Unions, enums, embedded resources and
  custom types are `term()`.
- Changing an action's arguments changes the callback: update every adapter and mock.

## Testing

- Mock the resource itself: `Mox.defmock(MyApp.WeatherMock, for: MyApp.Weather)` (or Hammox).
- Point the env at the mock in `test/test_helper.exs` or `config/test.exs`:
  `Application.put_env(:my_app, MyApp.Weather, MyApp.WeatherMock)`.
- Test callers through the code interface with `expect/3` on the mock.

## Verifying

- `AshAdapter.resolve(resource)` returns `{:ok, adapter}` or `{:error, message}`.
- `mix ash_adapter.verify` checks that every AshAdapter resource has an adapter exporting all
  callbacks. Run it with `MIX_ENV=dev`; mocks defined in `test_helper.exs` don't exist outside tests.
- Without an adapter the action raises `Ash.Error.Unknown` wrapping an `ArgumentError`.
