defmodule AshAdapter do
  @moduledoc """
  Swappable adapters for Ash generic actions, in the style of Knigge.

  Every generic action without `run` is dispatched to an adapter module, chosen at runtime.
  The resource becomes the behaviour: one `@callback` per dispatched action, taking the
  action's arguments in declaration order and returning what a `run` would return.

  See the README for usage.
  """

  use Spark.Dsl.Extension,
    sections: [
      %Spark.Dsl.Section{
        name: :adapter,
        describe: """
        Which module implements the resource's generic actions.
        Set either `otp_app` (resolved from the application env on every call) or `module`.
        """,
        examples: [
          """
          adapter do
            otp_app :my_app
            default MyApp.Weather.Http
          end
          """
        ],
        schema: [
          otp_app: [
            type: :atom,
            doc:
              "Application whose env holds the adapter: `config :my_app, MyApp.Weather, MyApp.Weather.Http`."
          ],
          config_key: [
            type: :atom,
            doc: "Key in the application env. Defaults to the resource module."
          ],
          default: [
            type: :atom,
            doc: "Adapter used when the application env has none."
          ],
          module: [
            type: :atom,
            doc: "Fixed adapter, skips the application env."
          ],
          pass_context?: [
            type: :boolean,
            default: false,
            doc:
              "Pass the `Ash.Resource.Actions.Implementation.Context` (actor, tenant, …) as last argument."
          ]
        ]
      }
    ],
    transformers: [AshAdapter.Transformer]

  @doc """
  The `reason` an adapter returned with `{:error, reason}`, taken from the error of a dispatched
  action; any other error is returned unchanged.

      {:error, error} = MyApp.Weather.forecast("Atlantis")
      AshAdapter.reason(error)
      #=> :unknown_city
  """
  @spec reason(term()) :: term()
  def reason(%Ash.Error.Unknown{errors: [%AshAdapter.Error{reason: reason}]}), do: reason
  def reason(error), do: error

  @doc "The adapter currently configured for the resource."
  @spec resolve(Ash.Resource.t()) :: {:ok, module()} | {:error, String.t()}
  def resolve(resource) do
    case Spark.Dsl.Extension.get_persisted(resource, :ash_adapter_source) do
      {:module, module} ->
        {:ok, module}

      {:env, otp_app, config_key, default} ->
        case Application.get_env(otp_app, config_key, default) do
          nil ->
            {:error,
             "no adapter for #{inspect(resource)}: set `config #{inspect(otp_app)}, #{inspect(config_key)}, MyAdapter` " <>
               "or `default` in the adapter section"}

          module ->
            {:ok, module}
        end
    end
  end

  @doc """
  Checks that the configured adapter of the resource is available and exports every callback.
  """
  @spec verify(Ash.Resource.t()) :: :ok | {:error, String.t()}
  def verify(resource) do
    with {:ok, adapter} <- resolve(resource),
         :ok <- ensure_loaded(adapter, resource) do
      missing =
        resource
        |> Spark.Dsl.Extension.get_persisted(:ash_adapter_callbacks)
        |> Enum.reject(fn {name, arity} -> function_exported?(adapter, name, arity) end)

      if missing == [] do
        :ok
      else
        {:error,
         "#{inspect(adapter)} lacks #{Enum.map_join(missing, ", ", fn {name, arity} -> "#{name}/#{arity}" end)} " <>
           "of #{inspect(resource)}"}
      end
    end
  end

  defp ensure_loaded(adapter, resource) do
    if Code.ensure_loaded?(adapter),
      do: :ok,
      else: {:error, "#{inspect(adapter)}, the adapter of #{inspect(resource)}, is not available"}
  end
end
