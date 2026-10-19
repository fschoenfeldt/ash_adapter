defmodule AshAdapter.TypespecTest do
  use ExUnit.Case, async: true

  alias AshAdapter.Typespec

  test "maps Ash types to typespecs" do
    assert spec(:string) == "String.t()"
    assert spec(:boolean) == "boolean()"
    assert spec(Ash.Type.UtcDatetime) == "DateTime.t()"
    assert spec({:array, :integer}) == "[integer()]"
    assert spec(:struct, instance_of: URI) == "URI.t()"
    assert spec(:struct) == "struct()"
  end

  test "falls back to term() for unknown types" do
    assert spec(:union) == "term()"
  end

  test "adds nil when nil is allowed" do
    assert :string |> Typespec.quoted([], true) |> Macro.to_string() == "String.t() | nil"
  end

  defp spec(type, constraints \\ []),
    do: type |> Typespec.quoted(constraints, false) |> Macro.to_string()
end
