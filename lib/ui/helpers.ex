defmodule UI.Helpers do
  alias Elui.Text.Span
  alias Elui.Text.Line
  alias Elui.Widgets.Paragraph
  alias Elui.Frame


  def render_title(frame, area, title)
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

  @spec get_product_ids() :: [binary()]
  def get_product_ids()
  do
    Registry.select(Product.Registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  def quit?(event)
  def quit?({:key, {:char, "q"}, _mods}), do: true
  def quit?({:key, :esc, _mods}), do: true
  def quit?(_event), do: false

  def cycle(index, delta, count) when count > 0 do
    rem(index + delta + count, count)
  end

  def cycle(index, _delta, _count), do: index

  def key?({:key, key, _mods}, keys), do: key in List.wrap(keys)
  def key?(_event, _keys), do: false


end
