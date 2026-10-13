

defmodule UI.ProductPage do
  import UI.Helpers

  alias Elui.Frame
  alias Elui.Widgets.Block
  alias Elui.Widgets.Paragraph
  alias Elui.Layout

  alias Elui.Widgets.List, as: UiList

  alias Elui.Text.Line
  alias Elui.Text.Span


  def init() do
  %{
      # product_ids: [],
      selected: 0,
      mode: :browse,
      input: ""
    }
  end

  defp delete_selected(model) do
    product_ids = get_product_ids()

    if product_ids == [] do
      model
    else
      product_id_to_del = Enum.at(product_ids, model.selected)
      # IO.puts(product_id_to_del)
      ProductSupervisor.Dynamic.stop_product(product_id_to_del)
      %{model | selected: min(model.selected, max(length(product_ids) - 1, 0))}
    end

  end


  def update(model, event) do
    case model.mode do
      :browse -> update_browse(model, event)
      :add -> update_add(model, event)
    end
  end

  defp add_product(%{input: ""} = model), do: {:ok, %{model | mode: :browse}}

  defp add_product(model) do
    ProductSupervisor.Dynamic.start_product(model.input)
    {:ok, %{model | mode: :browse, input: ""}}
  end

  defp toggle(model) do
    new_mode = case model.mode do
      :browse -> :add
      :add -> :browse
    end

    %{model | mode: new_mode}
  end

  defp update_browse(model, event) do
      product_ids = get_product_ids()

    cond do
      quit?(event) ->
        :quit

      key?(event, [:down, {:char, "j"}]) ->
        {:ok, %{model | selected: cycle(model.selected, 1, length(product_ids))}}

      key?(event, [:up, {:char, "k"}]) ->
        {:ok, %{model | selected: cycle(model.selected, -1, length(product_ids))}}

      key?(event, [:space, :enter]) ->
        {:ok, toggle(model)}

      key?(event, {:char, "a"}) ->
        {:ok, %{model | mode: :add, input: ""}}

      key?(event, {:char, "d"}) ->
        {:ok, delete_selected(model)}

      true ->
        {:ok, model}
    end
  end

  defp update_add(model, event) do
    cond do
      key?(event, :esc) ->
        {:ok, %{model | mode: :browse, input: ""}}

      key?(event, :enter) ->
        add_product(model)

      key?(event, :backspace) ->
        {:ok, %{model | input: String.slice(model.input, 0, max(String.length(model.input) - 1, 0))}}

      match?({:key, {:char, _}, []}, event) ->
        {:key, {:char, char}, []} = event
        {:ok, %{model | input: model.input <> char}}

      key?(event, :space) ->
        {:ok, %{model | input: model.input <> " "}}

      true ->
        {:ok, model}
    end
  end


  def view(model, frame) do
    [header, body, input, footer] =
      Layout.vertical([{:length, 2}, {:fill, 1}, {:length, 3}, {:length, 1}])
      |> Layout.split(Frame.area(frame))


    frame = render_title(frame, header, "Market Data Terminal App")
    frame = render_product_id_list(frame, model, body)
    frame = render_input(frame, model, input)
    frame = set_cursor(frame, model, input)
    frame
  end


  defp render_input(frame, model, area) do
    Frame.render_widget(
      frame,
      Paragraph.new(model.input,
        block:
          Block.bordered(
            title: if(model.mode == :add, do: "Add Product", else: "Press a to add"),
            border_style: [fg: if(model.mode == :add, do: :yellow, else: :dark_gray)]
          )
      ),
      area
    )
  end

  defp set_cursor(frame, model, area) do
    if model.mode == :add do
      Frame.set_cursor_position(frame, {area.x + 1 + String.length(model.input), area.y + 1})
    else
      frame
    end
  end

  defp render_product_id_list(frame, model, area) do
    product_ids = get_product_ids()

    items =
      Enum.map(product_ids, fn id ->
        Line.new([Span.new(id)]) end
      )


    {frame, _} = Frame.render_stateful_widget(
      frame,
      UiList.new(items,
        block: Block.bordered(title: "Products"),
        highlight_style: [bg: :blue],
        highlight_symbol: "> "
      ),
      area,
      UiList.State.new(selected: model.selected)
    )
    frame
  end




end
