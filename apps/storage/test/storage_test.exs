defmodule StorageTest do
  use ExUnit.Case
  doctest Storage

  setup_all do
    flow_name = "snapshot"
    flow_extension = ".json.gzip"
    flow_options = {flow_name, flow_extension}
    %{server_id: "https://ts8.x1.europe.travian.com", flow_options: flow_options}
  end

  @tag :tmp_dir
  test "file is stored in the right path as global if :global as identifier", %{
    tmp_dir: tmp_dir,
    flow_options: flow_options = {flow_name, flow_extension}
  } do
    root_folder = tmp_dir
    identifier = :global
    content = "alishdoifjasldjflk "

    :ok = Storage.store(root_folder, identifier, flow_options, content)

    filename =
      "#{root_folder}/global/#{flow_name}/date_#{Date.to_iso8601(Date.utc_today(), :basic)}#{flow_extension}"

    assert(File.read!(filename) == content)
  end

  @tag :tmp_dir
  test "file is stored in the right path with the right name with server_id as identifier", %{
    tmp_dir: tmp_dir,
    flow_options: flow_options = {flow_name, flow_extension},
    server_id: server_id
  } do
    root_folder = tmp_dir
    identifier = server_id
    content = "alishdoifjasldjflk "

    :ok = Storage.store(root_folder, identifier, flow_options, content)

    filename =
      "#{root_folder}/servers/#{TTypes.server_id_to_path(server_id)}/#{flow_name}/date_#{Date.to_iso8601(Date.utc_today(), :basic)}#{flow_extension}"

    assert(File.read!(filename) == content)
  end

  @tag :tmp_dir
  test "file is stored with a custom date", %{
    tmp_dir: tmp_dir,
    flow_options: flow_options = {flow_name, flow_extension},
    server_id: server_id
  } do
    root_folder = tmp_dir
    identifier = server_id
    content = "alishdoifjasldjflk "
    date = Date.utc_today() |> Date.add(10)

    :ok = Storage.store(root_folder, identifier, flow_options, content, date)

    filename =
      "#{root_folder}/servers/#{TTypes.server_id_to_path(server_id)}/#{flow_name}/date_#{Date.to_iso8601(date, :basic)}#{flow_extension}"

    assert(File.read!(filename) == content)
  end

  @tag :tmp_dir
  test "store and open returns the same file", %{
    tmp_dir: tmp_dir,
    flow_options: flow_options,
    server_id: server_id
  } do
    root_folder = tmp_dir
    identifier = server_id
    content = "alishdoifjasldjflk "
    date = Date.utc_today() |> Date.add(-10)

    expected = {date, content}

    :ok = Storage.store(root_folder, identifier, flow_options, content, date)
    {:ok, output} = Storage.open(root_folder, identifier, flow_options, date)
    check_f(expected, output)
  end

  @tag :tmp_dir
  test "store and open multiple files don't modify the contents or dates", %{
    tmp_dir: tmp_dir,
    flow_options: flow_options,
    server_id: server_id
  } do
    root_folder = tmp_dir
    identifier = server_id

    tups = %{
      (Date.utc_today() |> Date.add(10)) => "alskdjflajsdlfj",
      (Date.utc_today() |> Date.add(9)) => "aalsdkjflasjdflasj",
      (Date.utc_today() |> Date.add(8)) => "lasdjfoapudoasdfa",
      (Date.utc_today() |> Date.add(7)) => "9q28u3rljald",
      (Date.utc_today() |> Date.add(4)) => "290j392",
      (Date.utc_today() |> Date.add(2)) => "laksjdlfjasdf0q"
    }

    Enum.each(tups, fn {date, content} ->
      Storage.store(root_folder, identifier, flow_options, content, date)
    end)

    max = Date.utc_today() |> Date.add(9)
    min = Date.utc_today() |> Date.add(4)

    {:ok, outputs} = Storage.open(root_folder, identifier, flow_options, {min, max})

    assert(length(outputs) == 4)

    for output = {date, _content} <- outputs, do: check_f({date, Map.get(tups, date)}, output)
  end

  @tag :tmp_dir
  test "open a range of date with only one date returns one file", %{
    tmp_dir: tmp_dir,
    flow_options: flow_options,
    server_id: server_id
  } do
    root_folder = tmp_dir
    identifier = server_id
    date = Date.utc_today() |> Date.add(-8)

    content = "alishdoifjasldjflk "
    expected = {date, content}

    min = Date.utc_today() |> Date.add(-9)
    max = Date.utc_today() |> Date.add(-4)

    :ok = Storage.store(root_folder, identifier, flow_options, content, date)
    {:ok, [output]} = Storage.open(root_folder, identifier, flow_options, {min, max})
    check_f(expected, output)
  end

  @tag :tmp_dir
  test "use :consecutive to open only returns consecutive files", %{
    tmp_dir: tmp_dir,
    flow_options: flow_options,
    server_id: server_id
  } do
    root_folder = tmp_dir
    identifier = server_id

    tups = %{
      (Date.utc_today() |> Date.add(-10)) => "alskdjflajsdlfj",
      (Date.utc_today() |> Date.add(-9)) => "aalsdkjflasjdflasj",
      (Date.utc_today() |> Date.add(-8)) => "lasdjfoapudoasdfa",
      (Date.utc_today() |> Date.add(-4)) => "9q28u3rljald",
      (Date.utc_today() |> Date.add(-3)) => "290j392",
      (Date.utc_today() |> Date.add(-2)) => "laksjdlfjasdf0q"
    }

    Enum.each(tups, fn {date, content} ->
      Storage.store(root_folder, identifier, flow_options, content, date)
    end)

    min = Date.utc_today() |> Date.add(-10)
    max = Date.utc_today() |> Date.add(-2)

    {:ok, outputs} = Storage.open(root_folder, identifier, flow_options, {min, max, :consecutive})

    assert(length(outputs) == 3)

    expected_dates = [
      Date.utc_today() |> Date.add(-2),
      Date.utc_today() |> Date.add(-3),
      Date.utc_today() |> Date.add(-4)
    ]

    assert(Enum.map(outputs, fn {date, _} -> date end) == expected_dates)

    for output = {date, _content} <- outputs, do: check_f({date, Map.get(tups, date)}, output)
  end

  @tag :tmp_dir
  test "use :unique store the file under /server_id/unique/", %{
    tmp_dir: tmp_dir,
    flow_options: flow_options = {flow_name, flow_extension},
    server_id: server_id
  } do
    root_folder = tmp_dir
    identifier = server_id
    full_name = flow_name <> flow_extension
    content = "alishdoifjasldjflk "

    :ok = Storage.store(root_folder, identifier, flow_options, content, :unique)

    filename = "#{root_folder}/servers/#{TTypes.server_id_to_path(server_id)}/unique/#{full_name}"

    assert(File.read!(filename) == content)
  end

  @tag :tmp_dir
  test ":unique override if there is already a file", %{
    tmp_dir: tmp_dir,
    flow_options: flow_options = {flow_name, flow_extension},
    server_id: server_id
  } do
    root_folder = tmp_dir
    identifier = server_id
    full_name = flow_name <> flow_extension
    content1 = "alishdoifjasldjflk "
    content2 = "overrided content"

    :ok = Storage.store(root_folder, identifier, flow_options, content1, :unique)
    :ok = Storage.store(root_folder, identifier, flow_options, content2, :unique)

    filename = "#{root_folder}/servers/#{TTypes.server_id_to_path(server_id)}/unique/#{full_name}"

    assert(File.read!(filename) == content2)
  end

  @tag :tmp_dir
  test "open :unique retrieves the right file", %{
    tmp_dir: tmp_dir,
    flow_options: flow_options,
    server_id: server_id
  } do
    root_folder = tmp_dir
    identifier = server_id
    content = "alishdoifjasldjflk "

    :ok = Storage.store(root_folder, identifier, flow_options, content, :unique)

    {:ok, {:unique, stored_content}} =
      Storage.open(root_folder, identifier, flow_options, :unique)

    assert(content == stored_content)
  end

  @tag :tmp_dir
  test "exist? is true if the file exists else false", %{
    tmp_dir: tmp_dir,
    flow_options: flow_options,
    server_id: server_id
  } do
    root_folder = tmp_dir
    identifier = server_id
    content = "alishdoifjasldjflk "

    date = Date.utc_today()

    assert(false == Storage.exist?(root_folder, identifier, flow_options, :unique))
    assert(false == Storage.exist?(root_folder, identifier, flow_options, date))

    :ok = Storage.store(root_folder, identifier, flow_options, content, :unique)
    :ok = Storage.store(root_folder, identifier, flow_options, content, date)

    assert(true == Storage.exist?(root_folder, identifier, flow_options, :unique))
    assert(true == Storage.exist?(root_folder, identifier, flow_options, date))
  end

  defp check_f({date1, content1}, {date2, content2}) do
    assert(Date.compare(date1, date2) == :eq)
    assert(content1 == content2)
  end
end
