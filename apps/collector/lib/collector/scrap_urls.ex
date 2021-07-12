defmodule Collector.ScrapUrls do

  @typedoc """
  Url with http/https included
  """
  @type url :: String.t()


  @travibot "https://servers.travibot.com"
  @travibotpage "https://servers.travibot.com/?page="

  @headers [{"User-Agent", "Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:76.0) Gecko/20100101 Firefox/76.0"}]




  def get_current_urls() do
    case get_travibot_pages() do
      {:ok, pages} ->
	urls = Enum.map(pages, &get_urls/1)
	|> Enum.filter(fn {:ok, _urls} -> true
	  {:error, _reason} -> false end)
	|> Enum.reduce([], fn {:ok, urls}, acc -> urls ++ acc end)
	{:ok, urls}
      {:error, reason} -> {:error, {:cant_get_pages, reason}}
    end
  end

  @spec get_urls(page :: pos_integer()) :: {:ok, [url()]} | {:error, any()}
  defp get_urls(page) do
    case Finch.build(:get, @travibotpage <> Integer.to_string(page), @headers) |> Finch.request(TFinch) do
      {:ok, response} ->
	case response.status do
	  200 ->
	    handle_html(response.body)
	  bad_status ->
	    {:error, {:bad_status, bad_status}}
	end
      {:error, reason} ->
	{:error, reason}
    end
  end


  @spec handle_html(body :: String.t()) :: {:ok, [url()]} | {:error, any()}
  defp handle_html(html_body) do
    case Floki.parse_document(html_body) do # verify that is a good html, checking for table for example
      {:ok, html_tree} ->
	[_headers | rows] = String.split(html_body, "</tr>")    
	urls = Enum.map(rows, &pick_url_date/1)
	|> Enum.filter(fn {:error, :not_matched} -> false
	  {_url, :not_spawned} -> false
	  {_url, _date} -> true
	end)
	|> Enum.map(&to_init_date/1)
	{:ok, urls}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec pick_url_date(row :: String.t()) :: {String.t(), String.t()} | {String.t(), :not_spawned} | {:error, :not_matched}
  defp pick_url_date(row) do
    case String.split(row, "</td>", trim: true) do
      [_index, dirty_url, _dirty_date, _account] ->
	[_, dirty_url2] = String.split(dirty_url, ~s(<a href=\"))
	[url, _] = String.split(dirty_url2, ~s(/\" target=))
	{url, :not_spawned}
      [_index, dirty_url, dirty_date, _croppers, _elephants] ->
	[_, dirty_url2] = String.split(dirty_url, ~s(<a href=\"))
	[url, _] = String.split(dirty_url2, ~s(/\" target=))
	case (byte_size(dirty_date) -4 -21) do
	  days_size when days_size <= 4 ->
	    <<"<td>", dirty_date2::binary - size(days_size), "<span>days ago</span>">> = dirty_date
	    date = String.replace(dirty_date2, " ", "", global: true)
	    {url, date}
	  _days_size ->
	    {url, :not_spawned}
	end
      _ ->
	{:error, :not_matched}
      end
  end


  @spec to_init_date({url :: url(), days_ago :: pos_integer()}) :: {url(), Date.t()}
  defp to_init_date({url, days_ago}) do
    init = DateTime.utc_now()
    |> DateTime.add(-1*String.to_integer(days_ago)*24*3600)
    {url, init}
  end



  @spec get_travibot_pages() :: {:ok, [pos_integer()]} | {:error, any()}
  defp get_travibot_pages() do
    case Finch.build(:get, @travibot, @headers) |> Finch.request(TFinch) do
      {:ok, response} ->
	case response.status do
	  200 ->
	    max_page = get_last_page(response.body)
	    {:ok, Enum.to_list 1..max_page}
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
