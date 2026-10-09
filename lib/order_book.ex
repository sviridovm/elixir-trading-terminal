defmodule OrderBook do
  use Agent
  require Update
  alias OrderBook.State

  def start_link(product_id) do
    Agent.start_link(
      fn -> State.new() end,
      name: {:via, Registry, {OrderBookRegistry, product_id}}
    )
  end

  def add_order(product_id, order) do
    Agent.update(
      via(product_id),
      &State.add_order(&1, order)
    )
  end

  def apply_snapshot(product_id, updates)
    when is_binary(product_id)
    and is_list(updates)
  do
    Agent.update(
      via(product_id),
      State.new(updates)
    )
  end

  def apply_update(product_id, update)
    when Update.is_update(update)
    and is_binary(product_id)
  do
    Agent.update(
      via(product_id),
      &State.apply_update(&1, update)
    )
  end


  def get_bids(product_id) do
    Agent.get(
      via(product_id),
      &State.get_bids(&1)
    )
  end

  def get_asks(product_id) do
    Agent.get(
      via(product_id),
      &State.get_asks(&1)
    )
  end



  defp via(product_id) do
    {:via, Registry, {OrderBookRegistry, product_id}}
  end

end


defmodule OrderBook.State do
  alias OrderBook.State
  @type t :: %__MODULE__{
    bids: PriceLevels.t(),
    asks: PriceLevels.t(),
  }

  defstruct [:bids, :asks]

  @spec new() :: t()
  def new do
    %{
      bids: PriceLevels.new(),
      asks: PriceLevels.new()
    }
  end

  def new(updates) when is_list(updates) do
    apply_snapshot(new(), updates)
  end

  def apply_snapshot(order_book, updates) when is_list(updates) do
    if updates == [] do
      order_book
    else
      [update | remaining_updates] = updates
      order_book
      |> apply_update(update)
      |> apply_snapshot(remaining_updates)
    end
  end

  @spec apply_update(OrderBook.State.t(), Update.t()) :: nil
  def apply_update(order_book, update) when is_struct(order_book, OrderBook.State) and is_struct(update, Update) do
    add_order(order_book, Order.new(update))
  end



  @spec add_order(OrderBook.State.t(), Order.t()) :: OrderBook.State.t()
  def add_order(order_book, order) do
    case order.side do
    :buy ->
      %{order_book | bids: PriceLevels.add(order_book.bids, order)}
    :sell ->
      %{order_book | asks: PriceLevels.add(order_book.asks, order)}
    _ ->
      {:error, :invalid_side}
    end
  end

  def get_bids(orderBook) do
    PriceLevels.get_bids(orderBook.bids)
  end

  def get_asks(orderBook) do
    PriceLevels.get_asks(orderBook.asks)
  end

end
