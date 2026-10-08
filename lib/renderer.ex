defmodule MyApp.Counter do
  use TermUI.Elm

  # alias TermUI.Test.TestRenderer
  alias TermUI.Event
  alias TermUI.Renderer.Style

  def init(_opts), do: %{count: 0}

  def event_to_msg(%Event.Key{key: :up}, _state), do: {:msg, :increment}
  def event_to_msg(%Event.Key{key: :down}, _state), do: {:msg, :decrement}
  def event_to_msg(%Event.Key{key: "q"}, _state), do: {:msg, :quit}
  def event_to_msg(_, _), do: :ignore

  def update(:increment, state), do: {%{state | count: state.count + 1}, []}
  def update(:decrement, state), do: {%{state | count: state.count - 1}, []}
  def update(:quit, state), do: {state, [TermUI.Command.quit()]}

  def view(state) do
    stack(:vertical, [
      text("Counter Example", Style.new(fg: :cyan, attrs: [:bold])),
      text("", nil),
      text("Count: #{state.count}", nil),
      text("", nil),
      text("↑/↓ to change, Q to quit", Style.new(fg: :bright_black))
    ])
  end
end



defmodule DepthChart do
  use TermUI.Elm
  alias TermUI.Widgets.BarChart
  alias TermUI.Widgets.LineChart
  alias TermUI.Renderer.Style
  alias TermUI.Event

  def init(_opts) do
    OrderBook.new()
  end

  def view(_state) do
    orderbook = TestRender.getTestOB()

    # IO.inspect(orderbook)

    bids = OrderBook.getBids(orderbook)
    asks = OrderBook.getAsks(orderbook)

    # IO.inspect(bids)
    bids = Enum.map(bids, fn {_first, second} -> second end)
    asks = Enum.map(asks, fn {_first, second} -> second end)

    IO.inspect(bids)




    line_chart = LineChart.render(
      series: [
        %{data: bids},
        %{data: asks}
      ],
      width: 60,
      height: 10,
      min: 0,
      max: 100,
      style: Style.new(fg: :green)
    )

    stack(:vertical, [
      text("Line Char of whatever"),
      line_chart,
      text("Text below line chart")
    ])

  end

  def event_to_msg(%Event.Key{key: "q"}, _state), do: {:msg, :quit}
  def event_to_msg(_, _), do: :ignore

  def update(:quit, state), do: {state, [TermUI.Command.quit()]}


end

defmodule MyApp do
  @moduledoc """
  Entry point for the counter application.
  """

  def run do
    # TermUI.Runtime.run(root: MyApp.Counter)
    TermUI.Runtime.run(root: DepthChart)
  end

  def start do
    TermUI.Runtime.start_link(root: MyApp.Counter)
  end
end


defmodule TestRender do
  def getTestOB do
    1..20
    |> Enum.reduce(OrderBook.new(), fn _, ob ->
      order = Order.new(Enum.random(1..10), Enum.random(1..10),  Enum.random([:buy, :sell]))
      OrderBook.addOrder(ob, order)
    end)

  end
end
