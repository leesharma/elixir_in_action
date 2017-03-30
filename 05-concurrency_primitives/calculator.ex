defmodule Calculator do
  # sever behavior

  def start do
    calc_pid = spawn(fn -> loop(0) end)
    Process.register(calc_pid, :calc_pid)
  end

  defp loop(current_value) do
    new_value = receive do
      message -> process_message(current_value, message)
    end
    loop(new_value)
  end

  # public interface

  def value do
    send(:calc_pid, {:value, self()})
    receive do
      {:response, current_value} -> current_value
    end
  end

  def add(x), do: send(:calc_pid, {:add, x})
  def sub(x), do: send(:calc_pid, {:sub, x})
  def mul(x), do: send(:calc_pid, {:mul, x})
  def div(x), do: send(:calc_pid, {:div, x})

  # calls and casts

  defp process_message(current_value, {:add, x}), do: current_value + x
  defp process_message(current_value, {:sub, x}), do: current_value - x
  defp process_message(current_value, {:mul, x}), do: current_value * x
  defp process_message(current_value, {:div, x}), do: current_value / x

  defp process_message(current_value, {:value, caller}) do
    send(caller, {:response, current_value})
    current_value
  end

  defp process_message(current_value, invalid_request) do
    IO.puts "invalid request #{inspect invalid_request}"
    current_value
  end
end
