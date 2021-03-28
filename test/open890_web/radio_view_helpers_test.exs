defmodule Open890Web.RadioViewHelpersTest do
  use ExUnit.Case
  alias Open890Web.RadioViewHelpers

  describe "round_up_to_step/2" do
    test "chooses gets the correct value" do
      assert RadioViewHelpers.round_up_to_step(14_071_000, 3000) == 14_073_000
      assert RadioViewHelpers.round_up_to_step(14_057_000, 3000) == 14_058_000
      assert RadioViewHelpers.round_up_to_step(14_077_890, 3000) == 14_079_000
    end
  end

end
