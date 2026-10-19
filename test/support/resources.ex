defmodule AshAdapter.Test.Domain do
  @moduledoc false
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    allow_unregistered? true
  end
end

defmodule AshAdapter.Test.Weather do
  @moduledoc false
  use Ash.Resource, domain: AshAdapter.Test.Domain, extensions: [AshAdapter]

  adapter do
    otp_app :ash_adapter
  end

  actions do
    action :forecast, :string do
      description "Forecast for a city."
      argument :city, :string, allow_nil?: false
      argument :days, :integer, default: 1
    end

    action :ping

    action :local, :string do
      run fn _input, _context -> {:ok, "local"} end
    end
  end

  code_interface do
    define :forecast, args: [:city, {:optional, :days}]
    define :ping
    define :local
  end
end

defmodule AshAdapter.Test.Clock do
  @moduledoc false
  use Ash.Resource, domain: AshAdapter.Test.Domain, extensions: [AshAdapter]

  adapter do
    module AshAdapter.Test.FixedClock
  end

  actions do
    action :now, :string
  end

  code_interface do
    define :now
  end
end

defmodule AshAdapter.Test.FallbackClock do
  @moduledoc false
  use Ash.Resource, domain: AshAdapter.Test.Domain, extensions: [AshAdapter]

  adapter do
    otp_app :ash_adapter
    config_key :not_configured
    default AshAdapter.Test.FixedClock
  end

  actions do
    action :now, :string
  end

  code_interface do
    define :now
  end
end

defmodule AshAdapter.Test.UnconfiguredClock do
  @moduledoc false
  use Ash.Resource, domain: AshAdapter.Test.Domain, extensions: [AshAdapter]

  adapter do
    otp_app :ash_adapter
  end

  actions do
    action :now, :string
  end

  code_interface do
    define :now
  end
end

defmodule AshAdapter.Test.AlarmClock do
  @moduledoc false
  use Ash.Resource, domain: AshAdapter.Test.Domain, extensions: [AshAdapter]

  adapter do
    module AshAdapter.Test.FixedClock
  end

  actions do
    action :now, :string
    action :ring
  end
end

defmodule AshAdapter.Test.Greeter do
  @moduledoc false
  use Ash.Resource, domain: AshAdapter.Test.Domain, extensions: [AshAdapter]

  adapter do
    module AshAdapter.Test.ActorGreeter
    pass_context? true
  end

  actions do
    action :greet, :string do
      argument :greeting, :string, allow_nil?: false
    end
  end

  code_interface do
    define :greet, args: [:greeting]
  end
end

defmodule AshAdapter.Test.ActorGreeter do
  @moduledoc false
  @behaviour AshAdapter.Test.Greeter

  @impl true
  def greet(greeting, context), do: {:ok, "#{greeting}, #{context.actor.name}"}
end

defmodule AshAdapter.Test.FixedClock do
  @moduledoc false
  @behaviour AshAdapter.Test.Clock

  @impl true
  def now, do: {:ok, "noon"}
end
