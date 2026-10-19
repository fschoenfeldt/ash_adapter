defmodule AshAdapter.Transformer do
  @moduledoc false
  use Spark.Dsl.Transformer

  alias Ash.Resource.Actions.Action
  alias Spark.Dsl.Transformer
  alias Spark.Error.DslError

  @impl true
  def transform(dsl) do
    with {:ok, source} <- source(dsl) do
      context? = Transformer.get_option(dsl, [:adapter], :pass_context?, false)

      actions =
        dsl |> Transformer.get_entities([:actions]) |> Enum.filter(&match?(%Action{run: nil}, &1))

      dsl =
        Enum.reduce(actions, dsl, fn action, dsl ->
          run =
            {AshAdapter.Dispatch,
             arguments: Enum.map(action.arguments, & &1.name), context?: context?}

          Transformer.replace_entity(
            dsl,
            [:actions],
            %{action | run: run},
            &(&1.name == action.name)
          )
        end)

      callbacks =
        Enum.map(actions, &{&1.name, length(&1.arguments) + if(context?, do: 1, else: 0)})

      {:ok,
       dsl
       |> Transformer.persist(:ash_adapter_source, source)
       |> Transformer.persist(:ash_adapter_callbacks, callbacks)
       |> Transformer.eval([], Enum.map(actions, &callback(&1, context?)))}
    end
  end

  defp source(dsl) do
    resource = Transformer.get_persisted(dsl, :module)
    option = &Transformer.get_option(dsl, [:adapter], &1)

    case {option.(:module), option.(:otp_app)} do
      {nil, nil} ->
        {:error,
         DslError.exception(
           module: resource,
           path: [:adapter],
           message: "set either `otp_app` or `module`"
         )}

      {module, nil} ->
        {:ok, {:module, module}}

      {nil, otp_app} ->
        {:ok, {:env, otp_app, option.(:config_key) || resource, option.(:default)}}

      {_module, _otp_app} ->
        {:error,
         DslError.exception(
           module: resource,
           path: [:adapter],
           message: "`otp_app` and `module` exclude each other"
         )}
    end
  end

  defp callback(action, context?) do
    arguments =
      Enum.map(action.arguments, fn argument ->
        spec =
          AshAdapter.Typespec.quoted(argument.type, argument.constraints, argument.allow_nil?)

        quote(do: unquote(Macro.var(argument.name, nil)) :: unquote(spec))
      end)

    arguments =
      if context?,
        do: arguments ++ [quote(do: context :: Ash.Resource.Actions.Implementation.Context.t())],
        else: arguments

    result =
      if action.returns do
        spec = AshAdapter.Typespec.quoted(action.returns, action.constraints, action.allow_nil?)
        quote(do: {:ok, unquote(spec)} | {:error, term()})
      else
        quote(do: :ok | {:error, term()})
      end

    quote do
      @doc unquote(action.description)
      @callback unquote(action.name)(unquote_splicing(arguments)) :: unquote(result)
    end
  end
end
