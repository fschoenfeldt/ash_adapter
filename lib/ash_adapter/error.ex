defmodule AshAdapter.Error do
  @moduledoc """
  An `{:error, reason}` returned by an adapter, with the original `reason` kept for matching.

  Ash would otherwise turn a plain reason into an `Ash.Error.Unknown.UnknownError` that only
  carries `inspect(reason)`. The error is of class `:unknown`, so the code interface returns
  it inside an `Ash.Error.Unknown`:

      {:error, %Ash.Error.Unknown{errors: [%AshAdapter.Error{reason: :not_found}]}}

  Reasons that are already exceptions are passed on unchanged.
  """
  use Splode.Error, fields: [:reason, :resource, :action], class: :unknown

  @impl true
  def message(%{reason: reason, resource: resource, action: action}),
    do: "#{inspect(resource)}.#{action} failed: #{inspect(reason)}"
end
