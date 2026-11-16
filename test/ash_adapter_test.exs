defmodule AshAdapterTest do
  use ExUnit.Case, async: true

  import Mox

  alias AshAdapter.Test.AlarmClock
  alias AshAdapter.Test.Clock
  alias AshAdapter.Test.FallbackClock
  alias AshAdapter.Test.Greeter
  alias AshAdapter.Test.UnconfiguredClock
  alias AshAdapter.Test.Weather
  alias AshAdapter.Test.WeatherMock

  setup :verify_on_exit!

  describe "dispatch via application env" do
    test "passes the arguments in declaration order" do
      expect(WeatherMock, :forecast, fn "Berlin", 3 -> {:ok, "sunny"} end)

      assert Weather.forecast!("Berlin", 3) == "sunny"
    end

    test "passes argument defaults" do
      expect(WeatherMock, :forecast, fn "Berlin", 1 -> {:ok, "sunny"} end)

      assert Weather.forecast!("Berlin") == "sunny"
    end

    test "dispatches actions without return type" do
      expect(WeatherMock, :ping, fn -> :ok end)

      assert Weather.ping() == :ok
    end

    test "returns implementation errors as Ash errors" do
      expect(WeatherMock, :forecast, fn _city, _days -> {:error, "offline"} end)

      assert {:error, error} = Weather.forecast("Berlin")
      assert Exception.message(error) =~ "offline"
    end

    test "keeps the reason of implementation errors" do
      expect(WeatherMock, :forecast, fn _city, _days -> {:error, :offline} end)

      assert {:error,
              %Ash.Error.Unknown{
                errors: [%AshAdapter.Error{reason: :offline, action: :forecast}]
              }} = Weather.forecast("Berlin")
    end

    test "passes exceptions returned by the implementation on" do
      expect(WeatherMock, :forecast, fn _city, _days ->
        {:error, %RuntimeError{message: "offline"}}
      end)

      assert {:error, %Ash.Error.Unknown{errors: [%Ash.Error.Unknown.UnknownError{}]}} =
               Weather.forecast("Berlin")
    end

    test "keeps actions with their own run" do
      assert Weather.local!() == "local"
    end
  end

  test "the resource is the behaviour of its dispatched actions" do
    assert Enum.sort(Weather.behaviour_info(:callbacks)) == [forecast: 2, ping: 0]
  end

  test "callbacks are typed from the action's arguments and return type" do
    {:ok, callbacks} = Code.Typespec.fetch_callbacks(Weather)

    specs =
      for {{name, _arity}, [spec]} <- callbacks,
          do: name |> Code.Typespec.spec_to_quoted(spec) |> Macro.to_string()

    assert Enum.sort(specs) == [
             "forecast(city :: String.t(), days :: integer() | nil) :: {:ok, String.t()} | {:error, term()}",
             "ping() :: :ok | {:error, term()}"
           ]
  end

  test "pass_context? appends the action context" do
    assert Greeter.greet!("Hello", actor: %{name: "Ada"}) == "Hello, Ada"
    assert Greeter.behaviour_info(:callbacks) == [greet: 2]
  end

  describe "verify/1" do
    test "accepts an adapter with all callbacks" do
      assert AshAdapter.verify(Weather) == :ok
      assert AshAdapter.verify(Clock) == :ok
    end

    test "reports missing callbacks" do
      assert AshAdapter.verify(AlarmClock) ==
               {:error, "AshAdapter.Test.FixedClock lacks ring/0 of AshAdapter.Test.AlarmClock"}
    end

    test "reports a missing adapter" do
      assert {:error, "no adapter for AshAdapter.Test.UnconfiguredClock" <> _rest} =
               AshAdapter.verify(UnconfiguredClock)
    end
  end

  test "a fixed module skips the application env" do
    assert Clock.now!() == "noon"
  end

  test "default is used when the application env has no adapter" do
    assert FallbackClock.now!() == "noon"
  end

  test "raises when no adapter is configured" do
    assert_raise Ash.Error.Unknown,
                 ~r/no adapter for AshAdapter.Test.UnconfiguredClock/,
                 fn ->
                   UnconfiguredClock.now()
                 end
  end

  describe "adapter section" do
    test "requires otp_app or module" do
      assert_raise Spark.Error.DslError, ~r/set either `otp_app` or `module`/, fn ->
        defmodule NoSource do
          use Ash.Resource, domain: AshAdapter.Test.Domain, extensions: [AshAdapter]
        end
      end
    end

    test "rejects otp_app together with module" do
      assert_raise Spark.Error.DslError, ~r/exclude each other/, fn ->
        defmodule BothSources do
          use Ash.Resource, domain: AshAdapter.Test.Domain, extensions: [AshAdapter]

          adapter do
            otp_app :ash_adapter
            module AshAdapter.Test.FixedClock
          end
        end
      end
    end
  end
end
