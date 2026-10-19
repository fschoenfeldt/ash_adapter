defmodule AshAdapter.Dispatch do
  @moduledoc false
  use Ash.Resource.Actions.Implementation

  @impl true
  def run(input, opts, context) do
    arguments = Enum.map(opts[:arguments], &Map.get(input.arguments, &1))
    arguments = if opts[:context?], do: arguments ++ [context], else: arguments

    case AshAdapter.resolve(input.resource) do
      {:ok, adapter} -> apply(adapter, input.action.name, arguments)
      {:error, message} -> raise ArgumentError, message
    end
  end
end
