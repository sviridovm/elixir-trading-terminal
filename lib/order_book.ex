defmodule OrderBook do
  use Agent
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

  def remove_order(product_id, order_id) do
    Agent.update(
      via(product_id),
      &State.remove_order(&1, order_id)
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

  @type orderMap :: %{integer() => Order.t()}

  @type t :: %{
    orders: orderMap(),
    bids: PriceLevel.t(),
    asks: PriceLevel.t(),
  }

  @enforce_keys [:bids, :asks, :orders]
  defstruct [:bids, :asks, :orders]



  @spec new() :: t()
  def new do
    %{
      orders:  %{},
      bids: PriceLevel.new(),
      asks: PriceLevel.new()
    }
  end


  @spec add_order(OrderBook.State.t(), Order.t()) :: OrderBook.State.t()
  def add_order(order_book, order) do


    order_book = put_in(order_book, [:orders, order.id], order)
    case order.side do
    :buy ->
      %{order_book | bids: PriceLevel.add(order_book.bids, order)}
    :sell ->
      %{order_book | asks: PriceLevel.add(order_book.asks, order)}
    _ ->
      {:error, :invalid_side}
    end
  end

  @spec remove_order(State.t(), integer()) :: State.t()
  def remove_order(orderBook, orderId) do

    {_value, newMap} = Map.pop(orderBook, orderId)
    newMap
  end

  @spec reduce_order(State.t(), integer(), float()) :: State.t()
  def reduce_order(orderBook, orderId, amount) do
    newOrderBook =
      Map.update!(orderBook, orderId, fn order -> Order.decreaseQuantity(order, amount) end)

    if Order.getQuantity(newOrderBook[orderId]) <= 0 do
      remove_order(newOrderBook, orderId)
    else
      newOrderBook
    end
  end

  def get_bids(orderBook) do
    PriceLevel.getBids(orderBook.bids)
  end

  def get_asks(orderBook) do
    PriceLevel.getAsks(orderBook.asks)
  end

end
