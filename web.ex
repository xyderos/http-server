defmodule Web do

  def reply([?/ | path]) do
    case warning(path) do
      :ok ->
	case File.read(path) do
	  {:ok, content} ->
	    HTTP.ok(content)
	  {:error, _} ->
	    HTTP.fourofour()
	end
      _ ->
	HTTP.fourofour()
    end
  end

  def warning(path) do
    List.foldl(path, :ok,
      fn(c,a) ->
	case a do
	  :ok ->
	    if c == ?. do
	      :dot
	    else
	      :ok
	    end
	  :dot ->
	    if c == ?. do
	      :warning
	    else
	      :ok
	    end
	  :warning ->
	    :warning
	end
      end)
  end
end
