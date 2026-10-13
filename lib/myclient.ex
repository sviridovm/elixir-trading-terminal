defmodule CoinbaseClient do
  use WebSockex

  @url "wss://advanced-trade-ws.coinbase.com"

  def start_link(_)
  do
    IO.puts("Starting websockex process")
    WebSockex.start_link(@url, __MODULE__, %{subscriptions: MapSet.new(), pending: [], connected: false},
    name: __MODULE__
    #  debug: [:trace]
    )
  end


  defp add_product(product_id)
    when is_binary(product_id)
  do
    WebSockex.cast(__MODULE__, {:add_product_id, product_id})
  end
  def start_subscription(product_id)
    when is_binary(product_id)
  do
    add_product(product_id)
  end

  @impl true
  def handle_info(_msg, state) do
    {:ok, state}
  end

  defp send_subscription_message(product_id)
    when is_binary(product_id)
  do
    # IO.puts("sending subscription message for #{product_id}")
    sub_msg = CoinbaseClient.Messages.Subscribe.subscribe_message(product_id)
    send_message(sub_msg)
  end

  @impl true
  def handle_connect(_conn, state) do
    state = %{state | connected: true}
    Enum.each(state.pending, fn product_id ->
      send_subscription_message(product_id)
    end)

    subscriptions =
      Enum.reduce(state.pending, state.subscriptions, fn product_id, acc ->
        MapSet.put(acc, product_id)
      end)

    {:ok, %{state | connected: true, pending: [], subscriptions: subscriptions}}
  end

  @impl true
  def handle_frame({:text, msg}, state) do
    msg
    |> Jason.decode!(keys: :atoms)
    |> Router.dispatch()


    {:ok, state}
  end

  @impl true
  def handle_frame({:binary, data}, state) do
    IO.puts("Got binary: #{inspect(data)}")
    {:ok, state}
  end

  @impl true
  def handle_cast({:send, frame}, state) do
    {:reply, frame, state}
  end

  # @impl true
  # def handle_cast({:add_product_id, product_id}, %{connected: false} = state) do
  #   {:ok, %{state | pending: state.pending ++ [product_id]}}
  # end

  @impl true
  def handle_cast({:add_product_id, product_id}, %{connected: true} = state) do
    send_subscription_message(product_id)
    {:ok, %{state | subscriptions: MapSet.put(state.subscriptions, product_id)}}
  end

  @spec send_message(binary()) :: :ok
  def send_message(msg) when is_binary(msg) do
    WebSockex.cast(__MODULE__, {:send, {:text, msg}})
  end

  @impl true
  def handle_disconnect(info, state) do
    IO.inspect(info, label: "WEBSOCKET DISCONNECTED")
    {:ok, %{state | connected: false}}
  end


  @impl true
  def terminate(close_reason, state) do
    IO.puts("Stopping #{__MODULE__} because of #{close_reason}")
    IO.inspect(close_reason, label: "WEBSOCKET TERMINATING")
    IO.inspect(state, label: "FINAL STATE")

    state.subscriptions
    |> Enum.each(
      fn product_id ->
        unsub_msg = CoinbaseClient.Messages.Unsubscribe.message(product_id)
        send_message(unsub_msg)
      end
      )
    :ok
  end


end



defmodule APIEvent do
  @type t :: %__MODULE__{
          type: String.t(),
          product_id: String.t(),
          updates: [Update.t()]
        }

  def new(data) do
    %{
      data |
      updates: Enum.map(data[:updates] || [], &Update.new/1)
    }
    |> then(&struct!(APIEvent, &1))
  end

  defguard is_api_event(value) when is_struct(value, __MODULE__)

  defstruct [:type , :product_id, :updates]
end

defmodule Update do
  @type t :: %__MODULE__{
          side: String.t(),
          event_time: String.t(),
          price_level: String.t(),
          new_quantity: String.t()
        }
  @enforce_keys [:side, :event_time, :price_level, :new_quantity]
  defstruct [:side, :event_time, :price_level, :new_quantity]

  defguard is_update(value) when is_struct(value, __MODULE__)

  def new(data)
    when is_map(data)
  do
    struct!(Update, data)
  end

end


defmodule APIResponse do
  @type t :: %__MODULE__{
          channel: String.t(),
          timestamp: String.t(),
          sequence_num: integer(),
          events: [APIEvent.t()]
        }

  @enforce_keys [:channel, :timestamp, :sequence_num, :events]
  defstruct [:channel, :timestamp, :sequence_num, :events]

  def new(data) do
    %{
      data |
      events: Enum.map(data[:events] || [], &APIEvent.new/1)
    }
    |> then(&struct!(APIResponse, &1))
  end
end

defmodule Router do
  require Logger
  require APIEvent
  defp process_events([]), do: :ok

  defp process_events([event | rest])
    when APIEvent.is_api_event(event)
  do
    case event.type do
      "update"  -> OrderBook.apply_updates(event.product_id, event.updates)
      "snapshot" -> OrderBook.apply_snapshot(event.product_id, event.updates)
    end

    process_events(rest)
  end


  def dispatch(%{channel: "l2_data"} = data) do
    data = APIResponse.new(data)
    process_events(data.events)
  end

  def dispatch(%{channel: "subscribe"} = _data) do
  #   IO.puts("Subscribe message!")
  #   IO.inspect(data)
  end

  def dispatch(%{channel: "subscriptions"} = _data) do
  #   IO.inspect("Subscriptions Message!")
  #   IO.inspect(data)
  end

  def dispatch(data) do
    Logger.warning("Unknown channel #{inspect(data)}")
  end
end



defmodule CoinbaseClient.Messages.Subscribe do
  def subscribe_message(product_id) when is_binary(product_id) do
    Jason.encode!(Map.put(base_message(), :product_ids, [product_id]))
  end

  # def subscribe_message(product_ids) when is_list(product_ids) do
    # Jason.encode!(Map.put(base_message(), :product_ids, product_ids))
  # end

  defp base_message do
    %{
      type: "subscribe",
      channel: "level2"
    }
  end

end

defmodule CoinbaseClient.Messages.Unsubscribe do
  def message(product_id) when is_binary(product_id) do
    Jason.encode!(Map.put(base_message(), :product_ids, [product_id]))
  end

  defp base_message do
    %{
      type: "unsubscribe",
      channel: "level2"
    }
  end

end
