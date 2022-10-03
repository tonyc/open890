defmodule ExtractCommand do
  alias Open890.Extract

  defmacro extract(cmd, attr, opts \\ []) do
    fun = opts |> Keyword.get(:as, attr)

    quote do
      def dispatch(%__MODULE__{} = state, unquote(cmd) <> rest = msg) do
        state |> Map.put(unquote(attr), apply(Extract, unquote(fun), [msg]))
      end
    end
  end
end
