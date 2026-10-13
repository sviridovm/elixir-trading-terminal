defmodule OrderBook do
  use Agent
  alias OrderBook.State
  require Update

  @type t :: State.t()

  defguard is_order_book(value) when is_struct(value, OrderBook.State)

  def start_link(product_id) do
    Agent.start_link(
      fn -> State.new() end,
      name: via(product_id)
    )
  end

  def add_order(product_id, order) do
    Agent.update(
      via(product_id),
      &State.add_order(&1, order)
    )
  end

  @spec apply_snapshot(binary(), list(Update.t())) :: no_return()
  def apply_snapshot(product_id, updates)
    when is_binary(product_id)
    and is_list(updates)
  do
    Agent.update(
      via(product_id),
      fn _ -> State.new(updates) end
    )
  end



  @spec apply_updates(binary(), list(Update.t())) :: :ok
  def apply_updates(_product_id, [] = _updates)
  do
    :ok
  end

  def apply_updates(product_id, [update | rest])
    when Update.is_update(update)
  do
    apply_update(product_id, update)
    apply_updates(product_id, rest)
  end


  @spec apply_update(binary(), Update.t()) :: :ok
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

  def price_upper_bound(product_id) do
    Agent.get(
      via(product_id),
      &State.price_upper_bound(&1)
    )
  end


  defp via(product_id) do
    {:via, Registry, {OrderBook.Registry, product_id}}
  end

end


defmodule OrderBook.State do
  require Update
  alias OrderBook.State

  @type tree_type :: :gb_trees.tree(float(), float())
  @type t :: %__MODULE__{
    bids: PriceLevels.t(),
    asks: PriceLevels.t(),
  }

  defstruct [:bids, :asks]

  @spec new() :: t()
  def new do
    %__MODULE__{
      bids: PriceLevels.new(),
      asks: PriceLevels.new()
    }
  end

  defguard is_order_book(value) when is_struct(value, OrderBook.State)


  @spec new([Update.t()]) :: OrderBook.State.t()

  def new([] = _updates) do
    new()
  end

  def new(updates)
    when is_list(updates)
  do
    apply_snapshot(new(), updates)
  end

  @spec apply_snapshot(t(), list(Update.t())) :: t()

  def apply_snapshot(order_book, [] = _updates)
    when is_order_book(order_book)
  do
    order_book
  end

  def apply_snapshot(order_book, [update | remaining_updates])
    when is_order_book(order_book)
    when Update.is_update(update)
  do
    order_book
    |> apply_update(update)
    |> apply_snapshot(remaining_updates)
  end

  @spec apply_update(t(), Update.t()) :: t()
  def apply_update(order_book, update)
  when is_order_book(order_book)
  and Update.is_update(update)
  do
    add_order(order_book, Order.new(update))
  end

  @spec add_order(OrderBook.State.t(), Order.t()) :: OrderBook.State.t()
  def add_order(order_book, %Order{side: :buy} = order)
    when is_order_book(order_book)
  do
    %{order_book | bids: PriceLevels.add(order_book.bids, order)}
  end

  def add_order(order_book, %Order{side: :sell} = order)
    when is_order_book(order_book)
  do
    %{order_book | asks: PriceLevels.add(order_book.asks, order)}
  end

  @spec get_bids(OrderBook.State.t()) :: [{float(), float()}]
  def get_bids(order_book)
    when is_order_book(order_book)
  do
    PriceLevels.get_best_prices(order_book.bids, :buy)
  end

  @spec get_asks(OrderBook.State.t()) :: [{float(), float()}]
  def get_asks(order_book)
    when is_order_book(order_book)
  do
    PriceLevels.get_best_prices(order_book.asks, :sell)
  end

  def spread(order_book)
    when is_order_book(order_book)
  do
    PriceLevels.calculate_spread(order_book.bids, order_book.asks)
  end

  @spec price_upper_bound(t()) :: float()
  def price_upper_bound(order_book)
    when is_order_book(order_book)
  do
    max(PriceLevels.largest_price(order_book.bids), PriceLevels.largest_price(order_book.asks))
  end


end
