defmodule AshAdapter.Typespec do
  @moduledoc false

  @remote %{
    Ash.Type.CiString => quote(do: Ash.CiString.t()),
    Ash.Type.Date => quote(do: Date.t()),
    Ash.Type.DateTime => quote(do: DateTime.t()),
    Ash.Type.Decimal => quote(do: Decimal.t()),
    Ash.Type.Duration => quote(do: Duration.t()),
    Ash.Type.NaiveDatetime => quote(do: NaiveDateTime.t()),
    Ash.Type.String => quote(do: String.t()),
    Ash.Type.Time => quote(do: Time.t()),
    Ash.Type.TimeUsec => quote(do: Time.t()),
    Ash.Type.UUID => quote(do: String.t()),
    Ash.Type.UUIDv7 => quote(do: String.t()),
    Ash.Type.UtcDatetime => quote(do: DateTime.t()),
    Ash.Type.UtcDatetimeUsec => quote(do: DateTime.t())
  }

  @builtin %{
    Ash.Type.Atom => :atom,
    Ash.Type.Binary => :binary,
    Ash.Type.Boolean => :boolean,
    Ash.Type.Float => :float,
    Ash.Type.Integer => :integer,
    Ash.Type.Keyword => :keyword,
    Ash.Type.Map => :map,
    Ash.Type.Module => :module,
    Ash.Type.Term => :term
  }

  @doc "Quoted typespec of an Ash type; `term()` for types without a known mapping."
  def quoted(type, constraints, allow_nil?) do
    spec = type |> Ash.Type.get_type() |> spec(constraints)
    if allow_nil?, do: quote(do: unquote(spec) | nil), else: spec
  end

  defp spec({:array, type}, constraints),
    do: [spec(Ash.Type.get_type(type), constraints[:items] || [])]

  defp spec(Ash.Type.Struct, constraints) do
    case constraints[:instance_of] do
      nil -> quote(do: struct())
      module -> quote(do: unquote(module).t())
    end
  end

  defp spec(type, _constraints) do
    case {@remote[type], @builtin[type]} do
      {nil, nil} -> quote(do: term())
      {nil, builtin} -> {builtin, [], []}
      {remote, _builtin} -> remote
    end
  end
end
