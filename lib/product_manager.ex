defmodule ProductManager do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, MapSet.new(), name: __MODULE__)
  end

  def init(products) do
    {:ok, products}
  end

  def add_product(product_id) do
    GenServer.call(__MODULE__, {:add, product_id})
  end

  def remove_product(product_id) do
    GenServer.call(__MODULE__, {:remove, product_id})
  end

  def products do
    GenServer.call(__MODULE__, :products)
  end

  def handle_call({:add, product_id}, _from, products) do
    {:reply, :ok, MapSet.put(products, product_id)}
  end

  def handle_call({:remove, product_id}, _from, products) do
    {:reply, :ok, MapSet.delete(products, product_id)}
  end

  def handle_call(:products, _from, products) do
    {:reply, MapSet.to_list(products), products}
  end
end
