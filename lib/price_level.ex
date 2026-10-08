
defmodule PriceLevel do
  @type t :: :gb_trees.tree()
  def new do
    :gb_trees.empty()
  end

  def add(tree, order) do
  case :gb_trees.lookup(order.price, tree) do
    :none ->
      :gb_trees.insert(order.price, order.quantity, tree)

    {:value, quantity} ->
        :gb_trees.update(
          order.price,
          quantity + order.quantity,
          tree
        )
    end
  end

  def remove(plTree, price, amount) do
    oldQuantity = :gb_trees.get(price, plTree)
    if oldQuantity - amount <= 0 do
      :gb_trees.delete(price, plTree)
    else
      :gb_trees.update(price, oldQuantity - amount, plTree)
    end
  end

  def calculateSpread(bids, asks) do
    {_, bestBid} = :gb_trees.largest(bids)
    {_, bestAsk} = :gb_trees.smallest(asks)
    abs(bestAsk - bestBid)
  end



  def getBids(plTree) do
    getBestPrices(plTree, :buy)
  end

  def getAsks(plTree) do
    getBestPrices(plTree, :sell)
  end

  defp getBestPrices(plTree, side) do
    case side do
      :buy -> :gb_trees.to_list(plTree) |> Enum.reverse()
      :sell -> :gb_trees.to_list(plTree)
      _ -> :error
    end
  end
end
