defmodule Rudy do

  def start(port), do: Process.register(spawn(fn -> init(port) end), :rudy)


  def stop() do
    case Process.whereis(:rudy) do
      nil -> :ok
      pid -> Process.exit(pid, "Time to die!")
    end
  end

  defp init(port) do
    opt = [:list, active: false, reuseaddr: true]

    case :gen_tcp.listen(port, opt) do
      {:ok, listen} ->
        handler(listen)
        :gen_tcp.close(listen)
        :ok

      {:error, error} ->
        error
    end
  end

  defp handler(listen) do
    :io.format("ready: ~n", [])
    case :gen_tcp.accept(listen) do
      {:ok, client} ->
	{:ok, {ip, port}} = :inet.peername(client)
	:io.format("new connection: ~w ~w ~n", [ip, port])
	request(client)
	:io.format("closing connection~n", [])
        :gen_tcp.close(client)
        handler(listen)

      {:error, error} ->
        error
    end
  end

  defp request(client) do
    recv = :gen_tcp.recv(client, 0)
    case recv do
      {:ok, str} ->
	:io.format("request: ~s ~n", [str])
        request = HTTP.parse_request(str)
	:io.format("parsed: ~p ~n", [request])
        response = Rudy.reply(request)
	:io.format("response: ~s~n", [response])
        ##response = dummy()
        :gen_tcp.send(client, response)

      {:error, error} ->
        IO.puts("Rudy error: #{error}")
    end
  end

  def reply({{:get, uri, _}, _, _}), do: Web.reply(uri)

  defp dummy() do
    :timer.sleep(10)
    HTTP.ok("Hello!")
  end
end
