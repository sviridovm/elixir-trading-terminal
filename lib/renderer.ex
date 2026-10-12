defmodule Depth.Chart do
  @behaviour Elui.App

  alias Elui.Frame
  alias Elui.Widgets.Block
  alias Elui.Widgets.Chart
  alias Elui.Widgets.Paragraph
  alias Elui.Widgets.Chart.{Axis, Dataset}
  alias Elui.Layout

  alias Elui.Widgets.List, as: UiList

  alias Elui.Text.Line
  alias Elui.Text.Span

  @impl true
  def init(_opts), do: %{}

  @impl true
  def update(_model, {:key, {:char, "q"}, _mods}), do: :quit
  # def update(model, :tick), do: {:ok, %{model | phase: model.phase + 0.2}}
  def update(model, _event), do: {:ok, model}

  @impl true
  def view(_model, frame) do
    [header, body, input, footer] =
      Layout.vertical([{:length, 2}, {:fill, 1}, {:length, 3}, {:length, 1}])
      |> Layout.split(Frame.area(frame))


    frame = render_title(frame, header, "Market Data Terminal App")

    product_ids = Registry.select(Product.Registry, [{{:"$1", :_, :_}, [], [:"$1"]}])

    items =
      Enum.map(product_ids, fn id ->
        Line.new([Span.new(id)])
      end)

    frame =
      Frame.render_widget(
        frame,
        UiList.new(items,
          block: Block.bordered(title: "Products"),
          highlight_style: [bg: :blue],
          highlight_symbol: "> "
        ),
        body
      )

    # chart = render_depth_chart("ETH-USD")
    # Frame.render_widget(frame, chart, Frame.area(frame))
  end


  defp render_title(frame, area, title)
  do
     title_line =
      Line.new(
        [
          Span.new(title, fg: :yellow, add_modifier: [:bold]),
          # Span.new(if(help, do: "  #{help}", else: ""), fg: :dark_gray)
        ],
        alignment: :center
      )
    Frame.render_widget(frame, Paragraph.new([title_line]), area)
  end

  @spec render_depth_chart(binary()) :: Elui.Widgets.Chart.t()
  defp render_depth_chart(product_id) do
    bids = OrderBook.get_bids(product_id)
    asks = OrderBook.get_asks(product_id)
    highest_price = OrderBook.price_upper_bound(product_id)



    Chart.new(
      [
        Dataset.new(bids, name: "bids", graph_type: :line, style: [fg: :cyan]),
        Dataset.new(asks, name: "asks", graph_type: :line, style: [fg: :green])
      ],

      x_axis: Axis.new(title: "Price", bounds: {0.0, highest_price}),
      y_axis: Axis.new(title: "Quantity", bounds: {0.0, 10000.0}),
      block: Block.bordered(title: "Chart", title_bottom: "q to quit")
    )
  end

end


defmodule Examples.Chart do
  @behaviour Elui.App

  alias Elui.Frame
  alias Elui.Widgets.Block
  alias Elui.Widgets.Chart
  alias Elui.Widgets.Chart.{Axis, Dataset}

  @impl true
  def init(_opts), do: %{phase: 0.0}

  @impl true
  def update(_model, {:key, {:char, "q"}, _mods}), do: :quit
  def update(model, :tick), do: {:ok, %{model | phase: model.phase + 0.2}}
  def update(model, _event), do: {:ok, model}

  @impl true
  def view(model, frame) do
    sin_data =
      for i <- 0..200 do
        x = i / 10
        {x, :math.sin(x + model.phase)}
      end

    cos_data =
      for i <- 0..10 do
        x = i / 2
        {x, :math.cos(x + model.phase)}
      end

    chart =
      Chart.new(
        [
          Dataset.new(sin_data, name: "sin(x)", graph_type: :line, style: [fg: :cyan]),
          Dataset.new(cos_data, name: "cos(x)", graph_type: :scatter, style: [fg: :yellow])
        ],
        x_axis: Axis.new(title: "X", bounds: {0.0, 20.0}, labels: ["0", "10", "20"]),
        y_axis: Axis.new(title: "Y", bounds: {-1.5, 1.5}, labels: ["-1.5", "0", "1.5"]),
        block: Block.bordered(title: "Chart", title_bottom: "q to quit")
      )

    Frame.render_widget(frame, chart, Frame.area(frame))
  end
end


# Elui.App.run(Depth.Chart, [tick_rate: 500])
