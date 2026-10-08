defmodule Order do
  use Agent
  @type orderSide :: :buy | :sell

  @type t :: %__MODULE__{
          id: integer(),
          price: float(),
          quantity: integer(),
          side: orderSide()
        }

  @enforce_keys [:id, :price, :quantity, :side]
  defstruct [:id, :price, :quantity, :side]

  defguard is_order(value) when is_map(value) and value.__struct__ == Order

  @spec new(float(), integer(), orderSide()) :: Order.t()
  def new(price, quantity, side) do
    id = GlobalCounter.getNewID()
    %Order{id: id, price: price, quantity: quantity, side: side}
  end

    def child_spec([price, quantity, side]) do
      new(price, quantity, side)
    end

  @spec increaseQuantity(Order.t(), integer()) :: Order.t()
  def increaseQuantity(order, amount) do
    Map.update!(order, :quantity, fn quantity -> quantity + amount end)
  end

  @spec decreaseQuantity(Order.t(), integer()) :: Order.t()
  def decreaseQuantity(order, amount) do
    Map.update!(order, :quantity, fn quantity -> quantity - amount end)
  end

  @spec getQuantity(Order.t()) :: integer()
  def getQuantity(order) do
    order[:quantity]
  end
end



# defmodule OrderBook.Server do
#   use GenServer

#   def child_spec(init_arg) do
#     {OrderBook.Server, []}
#   end

#   def start_link(_) do
#     GenServer.start_link(__MODULE__, OrderBook.new(), name: __MODULE__)
#   end

#   def init(book) do
#     {:ok, book}
#   end

#   def add_order(order) do
#     GenServer.cast(__MODULE__, {:add_order, order})
#   end

#   def remove_order(order_id) do
#     GenServer.cast(__MODULE__, {:remove_order, order_id})
#   end

#   def reduce_order(order_id, amount) do
#     GenServer.cast(__MODULE__, {:reduce_order, order_id, amount})
#   end

#   def handle_cast({:add_order, order}, book) do
#     book = OrderBook.addOrder(book, order.id, order)
#     {:noreply, book}
#   end

#   def handle_cast({:remove_order, order_id}, book) do
#     book = OrderBook.removeOrder(book, order_id)
#     {:noreply, book}
#   end

#   def handle_cast({:reduce_order, order_id, amount}, book) do
#     book = OrderBook.reduceOrder(book, order_id, amount)
#     {:noreply, book}
#   end


# end



# what needs to be its own process

"""
every exchange
  every asset
    orders
      every order is long running, exists until cancelled or fulfulled

      should every order be its own agent,
      or should one big dict


    price level for bid side (for depth chart)
      for every price maintains a quantity
    price level for sell side (for depth chart)
      for every price maintains a quantity

"""
