defmodule Collector.ScrapUrls do

  @typedoc """
  Url with http/https included
  """
  @type url :: String.t()


  @travibot "https://servers.travibot.com"
  @travibotpage "https://servers.travibot.com/?page="

  @spec get_urls(page :: pos_integer()) :: {:ok, [url()]} | {:error, any()}
  def get_urls(page) do
    case Finch.build(:get, @travibotpage <> Integer.to_string(page)) |> Finch.request(TFinch) do
      {:ok, response} ->
	case response.status do
	  200 ->
	    response.body
	    #handle_html(response.body)
	  bad_status ->
	    {:error, {:bad_status, bad_status}}
	end
      {:error, reason} ->
	{:error, reason}
    end
  end


  @spec handle_html(body :: String.t()) :: {:ok, [url()]} | {:error, any()}
  defp handle_html(html_body) do
    case Floki.parse_document(html_body) do
      {:ok, html_tree} ->
	[_headers | rows] = String.split(html_body, "</tr>")    
      {:error, reason} -> {:error, reason}
    end
  end

  defp pick_url_date(row) do
    #String.split(uno, "</td>", trim: true)
    :ok
  end



  @spec get_travibot_pages() :: {:ok, [pos_integer()]} | {:error, any()}
  def get_travibot_pages() do
    case Finch.build(:get, @travibot) |> Finch.request(TFinch) do
      {:ok, response} ->
	case response.status do
	  200 ->
	    max_page = get_last_page(response.body)
	    Enum.to_list 1..max_page
	  bad_status ->
	    {:error, {:bad_status, bad_status}}
	end
      {:error, reason} ->
	{:error, reason}
    end
  end

  @spec get_last_page(html_body :: String.t()) :: pos_integer()
  defp get_last_page(html_body) do
    [part1, _] = String.split(html_body, ~s(">last<))
    [_, max_page] = String.split(part1, ~s(">next</a></li> <li><a href="?page=))
    String.to_integer(max_page)
  end





end
