defmodule Mix.Tasks.AshAdapter.Verify do
  @shortdoc "Checks that every AshAdapter resource has an adapter exporting all callbacks"

  @moduledoc """
  #{@shortdoc}.

  Runs against the application env of the current `MIX_ENV`. Adapters defined only at
  runtime, like Mox mocks from `test_helper.exs`, are not visible here; run it with `MIX_ENV=dev`.

      $ mix ash_adapter.verify
  """
  use Mix.Task

  @requirements ["compile", "app.config"]

  @impl true
  def run(_args) do
    app = Mix.Project.config()[:app]
    Application.load(app)

    resources =
      app
      |> Application.spec(:modules)
      |> Enum.filter(&(Spark.Dsl.is?(&1, Ash.Resource) and AshAdapter in Spark.extensions(&1)))

    case for resource <- resources,
             {:error, message} <- [AshAdapter.verify(resource)],
             do: message do
      [] -> Mix.shell().info("#{length(resources)} AshAdapter resource(s) verified")
      errors -> Mix.raise(Enum.join(errors, "\n"))
    end
  end
end
