defmodule Trudy do

  @handlers 8
  @name :trudy

  def start(port), do: Process.register(spawn(fn -> init(port) end), @name)

  def stop() do
    case Process.whereis(@name) do
      nil -> :ok
      pid -> Process.exit(pid, :kill)
    end
  end

  defp init(port) do
    opt = [:list, active: false, reuseaddr: true]
    case :gen_tcp.listen(port, opt) do
      {:ok, listen} ->
        Process.flag(:trap_exit, true)
        handlers(@handlers, listen)
        :gen_tcp.close(listen)
        :ok
      {:error, error} ->
        error
    end
  end

  defp supervise(listen) do
    receive do
      {:EXIT, _pid, reason}  -> log(reason)
	     spawn_link(fn() -> handler(listen) end)
	      supervise(listen)
      strange ->
	       :io.format("strange message: ~w~n", [strange])
	        supervise(listen)
    end
  end

  defp log(reason) when is_binary(reason) , do: :io.format("handler died: ~s~n", [reason])

  defp log(reason), do: :io.format("handler died: ~w~n", [reason])

  defp handlers(0, listen), do: supervise(listen)

  defp handlers(n, listen) do
    spawn_link(fn() -> handler(listen) end)
    handlers(n-1,  listen)
  end

  defp handler(listen) do
    case :gen_tcp.accept(listen) do
      {:ok, client} ->
        request(client)
	      :gen_tcp.close(client)
        handler(listen)

      {:error, error} -> error
    end
  end

  defp request(client) do
    recv = :gen_tcp.recv(client, 0)

    case recv do
      {:ok, str} ->
        request = HTTP.parse_request(str)
        response = reply(request)
        :gen_tcp.send(client, response)
      {:error, error} ->
        IO.puts("RUDY ERROR: #{error}")
    end
    :gen_tcp.close(client)
  end

  defp reply({{:get, _uri, _}, _, _}) do
    :timer.sleep(10)
    HTTP.ok("Hello!")
  end

  defp reply_file({{:get, uri, _}, _, _}), do: Web.reply(uri)

end
