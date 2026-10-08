defmodule OrderBook.Application do
  use Application

  @impl true
  def start(_start_type, _start_args) do
    children = [
      {GlobalCounter.Supervisor, []},
      {Registry, keys: :unique, name: OrderBookRegistry},
      {Registry, keys: :unique, name: CoinbaseClient.Registry},
      {Registry, keys: :unique, name: TradeStoreRegistry},
      {Registry, keys: :unique, name: ProductRegistry},
      {ProductSupervisor.Dynamic, []},
    ]

    IO.puts("Starting #{__MODULE__}!")

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end



defmodule GlobalCounter.Supervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children = [
      {GlobalCounter, 0}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

end

defmodule ProductSupervisor.Dynamic do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(
      __MODULE__,
      :ok,
      name: __MODULE__
    )
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_product(product_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {ProductSupervisor, product_id}
    )
  end

  def stop_product(product_id) do
  case Registry.lookup(ProductRegistry, product_id) do
    [{pid, _}] ->
      DynamicSupervisor.terminate_child(ProductSupervisor, pid)

    [] ->
      {:error, :not_found}
    end
  end

end

defmodule ProductSupervisor do
  use Supervisor

  def start_link(product_id) do
    Supervisor.start_link(
      __MODULE__,
      product_id,
      name: via(product_id)
    )
  end

  @impl true
  def init(product_id) do
    children = [
      {OrderBook, product_id},
      {TradeStore.Agent, product_id},
      {CoinbaseClient, product_id}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end


  defp via(product_id) do
    {:via, Registry, {ProductRegistry, product_id}}
  end


end


defmodule TradeStore.Supervisor do
  use DynamicSupervisor

  # starts supervisor process
  def start_link(_) do
    DynamicSupervisor.start_link(
      __MODULE__,
      :ok,
      name: __MODULE__
    )
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end


  # starts trade store process, with this module as the supervisor
  def start_trade_store(product_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {TradeStore.Agent, product_id}
    )
  end



end



defmodule OrderBook.Supervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(
      __MODULE__,
      :ok,
      name: __MODULE__
    )
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_order_book(product_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {OrderBook, product_id}
    )
  end


end


defmodule CoinbaseClient.Supervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(
      __MODULE__,
      :ok,
      name: __MODULE__
    )
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end


  def start_connection(product_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {CoinbaseClient, product_id}
    )



  end


end
