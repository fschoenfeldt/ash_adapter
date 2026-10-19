defmodule Mix.Tasks.AshAdapter.VerifyTest do
  use ExUnit.Case, async: true

  test "fails with every resource lacking an adapter or callbacks" do
    error = assert_raise Mix.Error, fn -> Mix.Tasks.AshAdapter.Verify.run([]) end

    assert error.message =~ "no adapter for AshAdapter.Test.UnconfiguredClock"

    assert error.message =~
             "AshAdapter.Test.FixedClock lacks ring/0 of AshAdapter.Test.AlarmClock"

    refute error.message =~ "AshAdapter.Test.Weather"
  end
end
