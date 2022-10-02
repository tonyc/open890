defmodule ExtractCommand do
  alias Open890.Extract
  defmacro extract(cmd, attr) do
    quote do
      def dispatch(%__MODULE__{} = state, unquote(cmd) <> _rest = msg) do
        state |> Map.put(unquote(attr), apply(Extract, unquote(attr), [msg]))
      end
    end
  end
end
