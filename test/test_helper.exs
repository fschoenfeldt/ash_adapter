Mox.defmock(AshAdapter.Test.WeatherMock, for: AshAdapter.Test.Weather)
Application.put_env(:ash_adapter, AshAdapter.Test.Weather, AshAdapter.Test.WeatherMock)

ExUnit.start()
