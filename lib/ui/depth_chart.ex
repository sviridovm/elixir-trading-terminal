defmodule UI.DepthChart do
  alias Elui.Frame
  alias Elui.Widgets.Block
  alias Elui.Widgets.Chart
  alias Elui.Widgets.Chart.{Axis, Dataset}
  alias Elui.Text.Line
  def init() do
    %{
      product_id: ""
    }
  end

  def update(model, _event) do
    {:ok, model}
  end

  def view(model, frame) do
    area = Frame.area(frame)
    render_depth_chart(frame, area, model.product_id)
  end

  defp render_depth_chart(frame, _area, _product_id, [] = _bids, _asks), do: frame
  defp render_depth_chart(frame, _area, _product_id, _bids, [] =  _asks), do: frame

  defp render_depth_chart(frame, area, product_id, bids, asks)
  do

    {best_bid, _} = List.first(bids, {0, 0})
    {best_ask, _} = List.first(asks, {0, 0})



    mid_market_price = (best_bid + best_ask) / 2

    {bid_depth, last_cum_bid} = cumulative_depth_and_last_point(bids)
    {ask_depth, last_cum_ask} = cumulative_depth_and_last_point(asks)

    {low_price, highestBidQuant} = last_cum_bid
    {high_price, highestAskQuant} = last_cum_ask

    highestQuant = max(highestAskQuant, highestBidQuant)

    mid_market_line = [{mid_market_price, 0}, {mid_market_price, highestQuant}]



    chart = Chart.new(
      [
        Dataset.new(bid_depth, name: "bids", graph_type: :bar, style: [fg: :red]),
        Dataset.new(ask_depth, name: "asks", graph_type: :bar, style: [fg: :green]),
        Dataset.new(mid_market_line, name: "mid market price: #{Float.round(mid_market_price, 2)}", graph_type: :line, style: [fg: :white])
      ],

      x_axis: Axis.new(title: "Price", bounds: {low_price, high_price}, labels: evenly_spaced(low_price, high_price, 10)),
      y_axis: Axis.new(title: "Quantity", bounds: {0.0, highestQuant}, labels: evenly_spaced(0, highestQuant, 10)),
      block: Block.bordered(title: Line.new("#{product_id} Depth Chart", alignment: :center), title_bottom: Line.new("q to quit", alignment: :center) )
    )


    frame = Frame.render_widget(frame, chart, area)
    frame

  end

  defp render_depth_chart(frame, _area, "" = _product_id), do: frame

  defp render_depth_chart(frame, area, product_id) do
    bids = OrderBook.get_bids(product_id) |> Enum.take(200)
    asks = OrderBook.get_asks(product_id) |> Enum.take(200)
    render_depth_chart(frame, area, product_id, bids, asks)
  end

  defp evenly_spaced(first, last, count) do
    Enum.map(0..(count - 1), fn i ->
      first + (last - first) * i / (count - 1)
      |> Float.round(2)
      |> to_string()
    end)
  end



  defp cumulative_depth_and_last_point(levels) do
    quantities = Enum.map(levels, fn {_price, quantity} -> quantity end)
    cumulative = Enum.scan(quantities, &+/2)

    {points, last_point} =
      Enum.map_reduce(
        Enum.zip_with(levels, cumulative, fn {price, _quantity}, total ->
          {price, total}
        end),
        nil,
        fn point, _last -> {point, point} end
      )

    {points, last_point}
  end


  defp cumulative_depth(levels) do
    quantities = Enum.map(levels, fn {_price, quantity} -> quantity end)

    cumulative = Enum.scan(quantities, &+/2)

    Enum.zip_with(levels, cumulative, fn {price, _quantity}, total ->
      {price, total} end
    )
  end
end
