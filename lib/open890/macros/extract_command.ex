defmodule ExtractCommand do
  alias Open890.Extract
  defmacro extract(cmd, attr, opts \\ []) do
    fun = case opts |> Keyword.get(:as) do
      :boolean -> :boolean
      nil -> attr
    end

    quote do
      def dispatch(%__MODULE__{} = state, unquote(cmd) <> _rest = msg) do
        state |> Map.put(unquote(attr), apply(Extract, unquote(fun), [msg]))
      end
    end
  end
end
