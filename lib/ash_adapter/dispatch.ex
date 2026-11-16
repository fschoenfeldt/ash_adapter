defmodule AshAdapter.Dispatch do
  @moduledoc false
  use Ash.Resource.Actions.Implementation

  @impl true
  def run(input, opts, context) do
    arguments = Enum.map(opts[:arguments], &Map.get(input.arguments, &1))
    arguments = if opts[:context?], do: arguments ++ [context], else: arguments

    case AshAdapter.resolve(input.resource) do
      {:ok, adapter} -> adapter |> apply(input.action.name, arguments) |> wrap_error(input)
      {:error, message} -> raise ArgumentError, message
    end
  end

  defp wrap_error({:error, reason}, input) when not is_exception(reason),
    do:
      {:error,
       AshAdapter.Error.exception(
         reason: reason,
         resource: input.resource,
         action: input.action.name
       )}

  defp wrap_error(result, _input), do: result
end
