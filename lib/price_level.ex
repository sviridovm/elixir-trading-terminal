
defmodule PriceLevels do
  @type t :: %__MODULE__{
    tree: :gb_trees.tree()
  }

  defstruct [:tree]

  def new do
    %__MODULE__{
      tree: :gb_trees.empty()
    }
  end

  defguard is_price_levels(value) when is_struct(value, PriceLevels)

  def add(price_levels, order)
    when is_price_levels(price_levels)
    and is_struct(order, Order.State)
    and order.quantity == 0
  do
    %{price_levels | tree: remove_price_level(price_levels, order.price)}
  end

  @spec add(t(), Order.t()) :: t()
  def add(price_levels, order)
    when is_price_levels(price_levels)
    and is_struct(order, Order.State) do
    %{price_levels | tree:  upsert_quantity(price_levels.tree, order.price, order.quantity)}
  end

  defp upsert_quantity(tree, price, quantity)
  do
    case :gb_trees.lookup(price, tree) do
      :none -> :gb_trees.insert(price, quantity, tree)
      {:value, existing} -> :gb_trees.update(price, existing + quantity, tree)
    end
  end
  @spec remove_price_level(t(), float()) :: t()
  def remove_price_level(price_levels, price) when is_price_levels(price_levels) and is_float(price) do
    :gb_trees.delete_any(price, price_levels.tree)
  end

  def remove(plTree, price, amount) do
    oldQuantity = :gb_trees.get(price, plTree)
    if oldQuantity - amount <= 0 do
      :gb_trees.delete(price, plTree)
    else
      :gb_trees.update(price, oldQuantity - amount, plTree)
    end
  end

  def calculate_spread(bids, asks) do
    {_, bestBid} = :gb_trees.largest(bids)
    {_, bestAsk} = :gb_trees.smallest(asks)
    abs(bestAsk - bestBid)
  end

  def get_bids(plTree) do
    get_best_prices(plTree, :buy)
  end

  def get_asks(plTree) do
    get_best_prices(plTree, :sell)
  end

  defp get_best_prices(plTree, side) do
    case side do
      :buy -> :gb_trees.to_list(plTree) |> Enum.reverse()
      :sell -> :gb_trees.to_list(plTree)
      _ -> :error
    end
  end
end
