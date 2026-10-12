

defmodule TradeStore.Agent do
  use Agent
  alias TradeStore

  def start_link(product_id) do
    Agent.start_link(
      fn -> TradeStore.new() end,
      name: via(product_id)
    )
  end

  defp via(product_id) do
      {:via, Registry, {TradeStore.Registry, product_id}}
  end

  def add_trade(product_id, trade) do
    Agent.get(via(product_id), &add_trade(&1, trade))
  end


end


defmodule TradeStore do
  @type t :: %{
    trades: :queue.queue(Trade.t())
  }
  @max_size 200

  @enforce_keys(:trades)
  defstruct [:trades]

  def new do
    %{trades: :queue.new()}
  end

  def remove_oldest_trade(trade_store) do
    :queue.drop(trade_store)
  end

  defp add_trade_no_check(trade_store, trade) do
    :queue.in(trade_store, trade)
  end

  def add_trade(trade_store, trade) do
    if size(trade_store) == @max_size do
      trade_store
      |> remove_oldest_trade()
      |> add_trade_no_check(trade)
    else
      trade_store
      |> add_trade_no_check(trade)
    end
  end

  def size(trade_store) do
    :queue.len(trade_store)
  end

end


defmodule Trade do
  @type side :: :buy | :sell


  @type t :: %{
    time: binary(),
    price: float(),
    size: float(),
    side: side()
  }

end
