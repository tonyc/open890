defmodule Open890.FrequencyEntryParserTest do
  use ExUnit.Case

  alias Open890.FrequencyEntryParser, as: Parser

  describe "parse/2" do
    test "parses frequency under 10mhz with no periods" do
      assert Parser.parse("9 999 999") == "00009999999"
    end

    test "parses frequency under 10 mhz with not enough digits" do
      assert Parser.parse("9")        == "00009000000"
      assert Parser.parse("91")       == "00009100000"
      assert Parser.parse("912")      == "00009120000"
      assert Parser.parse("9123")     == "00009123000"
      assert Parser.parse("91234")    == "00009123400"
      assert Parser.parse("912345")   == "00009123450"
      assert Parser.parse("9123456")  == "00009123456"
    end

    test "parses frequency under 10 mhz with too many digits" do
      assert Parser.parse("91234567") == "00009123456"
    end

    test "handles frequency over 10mhz with no periods" do
      assert Parser.parse("14 203 456") == "00014203456"
    end

    test "parses frequency over 10mhz with not enough digits" do
      assert Parser.parse("1")        == "00010000000"
      assert Parser.parse("12")       == "00012000000"
      assert Parser.parse("123")      == "00012300000"
      assert Parser.parse("1234")     == "00012340000"
      assert Parser.parse("12345")    == "00012345000"
      assert Parser.parse("123456")   == "00012345600"
      assert Parser.parse("1234567")  == "00012345670"
      assert Parser.parse("12345678") == "00012345678"
    end

    test "parses frequency over 10 mhz with too many digits" do
      assert Parser.parse("12345678912355") == "00012345678"
    end
  end
end
