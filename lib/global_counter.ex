defmodule GlobalCounter do
  use Agent

  @name __MODULE__
  def start_link(initial_value \\ 0) do
    IO.puts("global counter startlink is called")
    Agent.start_link(fn -> initial_value end, name: @name)
  end

  def getNewID do
    value = value()
    increment()
    value
  end

  defp value do
    Agent.get(@name, & &1)
  end

  defp increment do
    Agent.update(@name, &(&1 + 1))
  end
end


# children = [
#   {GlobalCounter, 0}
# ]

# Supervisor.start_link(children, strategy: :one_for_all)
