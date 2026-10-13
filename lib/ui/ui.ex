defmodule UI do
  import UI.Helpers
  @behaviour Elui.App

  @impl true
  def init(_opts) do
    %{
      current_page: :products,
      selected: 0,
      products: UI.ProductPage.init(),
      chart: UI.DepthChart.init(),
    }
  end

  @impl true
  def update(_model, {:key, {:char, "q"}, _mods}), do: :quit


  def update(%{current_page: :products} = model, event) do
    cond do
      quit?(event) -> :quit
      key?(event, [:tab]) -> products_to_chart_switch(model)
      true -> update_product_page(model, event)
    end
  end


  def update(%{current_page: :chart} = model, event) do
    cond do
      key?(event, [:esc, {:char, "q"}]) -> escape_chart(model)
      true -> update_chart(model, event)
    end
  end

  def update(model, _event), do: {:ok, model}

  defp update_chart(%{current_page: :chart} = model, event) do
    {_, chart} =  UI.DepthChart.update(model.chart, event)
    {:ok, %{model | chart: chart}}
  end

  defp escape_chart(%{current_page: :chart} = model) do
    {:ok, %{model | current_page: :products}}
  end

  defp update_product_page(%{current_page: :products} = model, event) do
    {_, products} =  UI.ProductPage.update(model.products, event)
    {:ok, %{model | products: products}}
  end

  defp products_to_chart_switch(%{current_page: :products} = model) do
    product_ids = get_product_ids()

    if product_ids == [] do
      # do nothing
      {:ok, model}
    else
      chart = Map.update!(model.chart, :product_id, fn _ -> Enum.at(product_ids, model.products.selected, "") end)
      {:ok, %{model | current_page: :chart, selected: model.products.selected ,chart: chart}}
    end
  end



  @impl true
  def view(model, frame) do
    case model.current_page do
      :products -> UI.ProductPage.view(model.products, frame)
      :chart -> UI.DepthChart.view(model.chart, frame)

    end
  end




end
