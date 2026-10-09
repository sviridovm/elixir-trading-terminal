defmodule TestRender do
  def getTestOB do
    1..20
    |> Enum.reduce(OrderBook.new(), fn _, ob ->
      order = Order.new(Enum.random(1..10), Enum.random(1..10),  Enum.random([:buy, :sell]))
      OrderBook.State.add_order(ob, order)
    end
    )

  end
end
