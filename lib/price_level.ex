
defmodule PriceLevels do
  require Order
  @type tree_type :: :gb_trees.tree(float(), float())

  @type price_quantity_pair :: {float(), float()}

  @type t :: %__MODULE__{
    # price -> quantity
    tree: tree_type()
  }

  defstruct [:tree]

  @spec new() :: PriceLevels.t()
  def new do
    %__MODULE__{
      tree: :gb_trees.empty()
    }
  end

  defguard is_price_levels(value) when is_struct(value, PriceLevels)

  def add(price_levels, order)
    when is_price_levels(price_levels)
    and Order.is_order(order)
    and order.quantity == 0
  do
    remove_price_level(price_levels, order.price)
  end

  @spec add(t(), Order.t()) :: t()
  def add(price_levels, order)
    when is_price_levels(price_levels)
    and Order.is_order(order)
  do
    %{price_levels | tree:  upsert_quantity(price_levels.tree, order.price, order.quantity)}
  end

  @spec upsert_quantity(tree_type(), float(), float()) :: tree_type()
  defp upsert_quantity(tree, price, quantity)
  do
    case :gb_trees.lookup(price, tree) do
      :none -> :gb_trees.insert(price, quantity, tree)
      {:value, existing} -> :gb_trees.update(price, existing + quantity, tree)
    end
  end
  @spec remove_price_level(t(), float()) :: t()
  def remove_price_level(price_levels, price) when is_price_levels(price_levels) and is_float(price) do
    %{price_levels | tree: :gb_trees.delete_any(price, price_levels.tree)}
  end

  @spec remove(tree_type(), float(), float()) :: tree_type()
  def remove(tree, price, amount) do
    oldQuantity = :gb_trees.get(price, tree)
    if oldQuantity - amount <= 0 do
      :gb_trees.delete(price, tree)
    else
      :gb_trees.update(price, oldQuantity - amount, tree)
    end
  end

  @spec calculate_spread(tree_type(), tree_type()) :: float()
  def calculate_spread(bids, asks) do
    {_, bestBid} = :gb_trees.largest(bids)
    {_, bestAsk} = :gb_trees.smallest(asks)
    abs(bestAsk - bestBid)
  end


  @spec largest_price(t()) :: float()
  def largest_price(price_levels)
    when is_price_levels(price_levels)
  do
    {key, _} = :gb_trees.largest(get_tree(price_levels))
    key
  end

  # @spec smallest(t()) :: float()
  # def smallest(price_levels)
  #   when is_price_levels(price_levels)
  # do
  #   {_, smallest} = :gb_trees.smallest(get_tree(price_levels))
  #   smallest
  # end

  @spec smallest_price(t()) :: float()
  def smallest_price(price_levels)
    when is_price_levels(price_levels)
  do
    {key, _value} = :gb_trees.smallest(get_tree(price_levels))
    key
  end



  @spec get_tree(t()) :: tree_type()
  defp get_tree(price_levels)
    when is_price_levels(price_levels)
  do
    price_levels.tree
  end


  @spec get_best_prices(t(), Order.order_side()) :: list(price_quantity_pair())
  def get_best_prices(price_levels, :buy = _side)
    when is_price_levels(price_levels)
  do
    :gb_trees.to_list(get_tree(price_levels)) |> Enum.reverse()
  end

  def get_best_prices(price_levels, :sell = _side)
    when is_price_levels(price_levels)
  do
    :gb_trees.to_list(get_tree(price_levels))
  end
end
