defmodule CoinbaseClient do
  use WebSockex

  @url "wss://advanced-trade-ws.coinbase.com"

  def start_link(product_id) do
    WebSockex.start_link(@url, __MODULE__, %{product_id: product_id}, name: via(product_id))
  end

  @impl true
  def handle_connect(_conn, state) do
    product_id = Map.get(state, :product_id)
    sub_msg = CoinbaseClient.Messages.Subscribe.subscribe_message(product_id)
    send_message(sub_msg, product_id)

    {:ok, state}
  end

  @impl true
  def handle_frame({:text, msg}, state) do
    # IO.puts("Got: #{msg}")
    # IO.puts("trying")
    msg
    |> Jason.decode!(keys: :atoms)
    |> Router.dispatch(Map.get(state, :product_id))


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

  def send_message(msg, product_id) when is_binary(msg) and is_binary(product_id) do
    case Registry.lookup(CoinbaseClient.Registry, product_id) do
    [{pid, _}] ->
        WebSockex.cast(pid, {:send, {:text, msg}})
    [] ->
      {:error, :not_found}
    end
  end

  @impl true
  def terminate(_close_reason, state) do
    product_id = Map.get(state, :product_id)
    unsub_msg = CoinbaseClient.Messages.Unsubscribe.message(product_id)
    send_message(unsub_msg, product_id)

  end

  defp via(product_id) do
    {:via, Registry, {CoinbaseClient.Registry, product_id}}
  end

end

defmodule OrderBooky do
  def printUpdate(msg) do

    parsed_msg = struct!(APIResponse, msg)
    events = parsed_msg.events

    Enum.each(events, fn event ->

      case event.type do
        "update" -> IO.inspect(event)
        "snapshot" ->
          IO.puts("--------\n")
          IO.puts("Snapshot Update")
          IO.inspect(event)
          IO.puts("--------\n")
            _ -> :error
      end


    end)

  end
end



defmodule Router do
  require Logger

  def dispatch(%{channel: "l2_data"} = data, product_id) do
    # OrderBooky.printUpdate(data)
    IO.puts("Received message from #{product_id}")
  end

  def dispatch(%{channel: "subscribe"} = data, product_id) do
    IO.puts("Subscribe message!")
    IO.inspect(data)
  end

  def dispatch(%{channel: "subscriptions"} = data, product_id) do
    IO.inspect("Subscriptions Message!")
    IO.inspect(data)
  end

  def dispatch(data, product_id) do
    Logger.warning("Unknown channel #{inspect(data)}")
  end
end

# defmodule ProductPrice do
#   require Order

#   @type t :: %__MODULE__{
#           product_id: String.t(),
#           bid_side: Agent.agent(),
#           sell_side: Agent.agent()
#         }

#   defstruct [:product_id, :bid_side, :sell_side]

#   defguard is_productprice(value) when is_map(value) and value.__struct__ == ProductPrice

#   @spec start(String.t()) :: ProductPrice.t()
#   def start(product_id) when is_binary(product_id) do
#     # {:ok, bid_side_pid} = Agent.start_link(fn -> %Order{} end)
#     # {:ok, sell_side_pid} = Agent.start_link(fn -> %Order{} end)
#     # :persistent_term.put({:ProductPrice, :product_id}, product_id)

#     # %__MODULE__{product_id: product_id, bid_side: bid_side_pid, sell_side: sell_side_pid}
#   end

#   @spec read(ProductPrice.t()) :: String.t()
#   def read(%__MODULE__{} = pp) do
#     # :persistent_term.get({:ProductPrice, :product_id})
#     pp.product_id
#   end

#   @spec update(ProductPrice.t(), String.t(), Order.t()) :: ProductPrice.t()
#   def update(%__MODULE__{} = pp, side, order)
#       when is_productprice(pp) and is_binary(side) and Order.is_order(order) do
#     cond do
#       side == "bid" -> Agent.update(pp.bid_side, fn state -> order end)
#       side == "offer" -> Agent.update(pp.sell_side, fn state -> order end)
#     end

#     pp
#   end

#   def readBid(%__MODULE__{} = pp) do
#     Agent.get(pp.bid_side, fn state -> state end)
#   end
# end

defmodule Update do
  @type t :: %__MODULE__{
          side: String.t(),
          event_time: String.t(),
          price_level: String.t(),
          new_quantity: String.t()
        }

  defstruct [:side, :event_time, :price_level, :new_quantity]
end

defmodule APIEvent do
  @type t :: %__MODULE__{
          type: String.t(),
          product_id: String.t(),
          updates: [Update.t()]
        }

  defstruct [:type, :product_id, :updates]
end

defmodule APIResponse do
  @type t :: %__MODULE__{
          channel: String.t(),
          timestamp: String.t(),
          sequence_num: integer(),
          events: [APIEvent.t()]
        }

  defstruct [:channel, :timestamp, :sequence_num, :events]

  def print_channel(%APIResponse{} = response) do
    # Enum.each(events, IO.puts/1)
    IO.puts(response.channel)
  end
end


defmodule CoinbaseClient.Messages.Subscribe do
  def subscribe_message(product_id) when is_binary(product_id) do
    Jason.encode!(Map.put(base_message(), :product_ids, [product_id]))
  end

  def subscribe_message(product_ids) when is_list(product_ids) do
    Jason.encode!(Map.put(base_message(), :product_ids, product_ids))
  end

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




defmodule ReadOnce do
  def read do
    msg = CoinbaseClient.Messages.Subscribe.subscribe_message("ETH-USD")

    {:ok, pid} = CoinbaseClient.start_link()

    WebSockex.cast(pid, {:send, {:text, msg}})

    Process.sleep(:infinity)
  end
end



# Run the application
# TermUI.Runtime.run(root: Counter)

# defmodule Test do
#   def run do
#     pp = ProductPrice.start("1")
#     # y = ProductPrice.start(5)

#     ProductPrice.read(pp) |> IO.puts()

#     ProductPrice.update(pp, "bid", %Order{quantity: 100, price: 10.0})
#     ProductPrice.readBid(pp) |> IO.inspect()

#     ProductPrice.update(pp, "bid", %Order{quantity: 200, price: 5.0})
#     ProductPrice.readBid(pp) |> IO.inspect()
#   end
# end

# Test.run()

# ProductPrice.read(y) |> IO.puts
