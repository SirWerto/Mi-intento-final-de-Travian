defmodule Satellite.MedusaTable do
  require Record

  @table_name :medusa_table

  @enforce_keys [
    :player_id,
    :player_name,
    :player_url,
    :server_id,
    :server_url,
    :alliance_id,
    :alliance_name,
    :alliance_url,
    :inactive_in_future,
    :inactive_probability,
    :inactive_in_current,
    :total_population,
    :model,
    :n_villages,
    :target_date,
    :creation_dt
  ]

  defstruct [
    :player_id,
    :player_name,
    :player_url,
    :server_id,
    :server_url,
    :alliance_id,
    :alliance_name,
    :alliance_url,
    :inactive_in_future,
    :inactive_probability,
    :inactive_in_current,
    :total_population,
    :model,
    :n_villages,
    :target_date,
    :creation_dt
  ]

  @type t :: %__MODULE__{
          player_id: TTypes.player_id(),
          player_name: TTypes.player_name(),
          player_url: binary(),
          server_id: TTypes.server_id(),
          server_url: binary(),
          alliance_id: TTypes.alliance_id(),
          alliance_name: TTypes.alliance_name(),
          alliance_url: binary(),
          inactive_in_future: boolean(),
          inactive_probability: float(),
          inactive_in_current: boolean() | :undefined,
          total_population: pos_integer(),
          model: Medusa.Pipeline.Step2.fe_type(),
          n_villages: pos_integer(),
          target_date: Date.t(),
          creation_dt: DateTime.t()
        }

  @spec create_table(nodes :: [atom()]) :: {:atomic, any()} | {:aborted, any()}
  def create_table(nodes) do
    options = [
      attributes: [
        :player_id,
        :server_id,
        :struct
      ],
      type: :set,
      disc_copies: nodes,
      index: [:server_id]
    ]

    :mnesia.create_table(@table_name, options)
  end

  @spec insert_predictions(medusa_structs :: [t()]) :: :ok | {:error, any()}
  def insert_predictions(medusa_structs) do
    func = fn ->
      for x <- medusa_structs, do: :mnesia.write({@table_name, x.player_id, x.server_id, x})
    end

    :mnesia.activity(:transaction, func)
  end

  @spec get_predictions_by_server(server_id :: TTypes.server_id(), target_date :: Date.t()) :: :ok
  def get_predictions_by_server(server_id, target_date \\ Date.utc_today()) do
    pattern = {@table_name, :_, server_id, :_}

    func = fn -> :mnesia.match_object(pattern) end
    answer = :mnesia.activity(:transaction, func)
    for {@table_name, _player_id, _server_id, row} <- answer, row.target_date == target_date, do: row
  end

  # QLC for the query?
  @spec get_unique_servers() :: {:ok, [TTypes.server_id()]} | {:error, any()}
  def get_unique_servers() do
    pattern = {@table_name, :_, :_, :_}

    func = fn -> :mnesia.match_object(pattern) end
    result = for res <- :mnesia.activity(:transaction, func), uniq: true, do: elem(res, 2)
    {:ok, result}
  end

  # -include_lib("stdlib/include/qlc.hrl").

  # select_distinct()->
  #     QH = qlc:q( [K || {_TName, K, _V} <- mnesia:table(test)], {unique, true}),
  #     F = fun() -> qlc:eval(QH) end,
  #     {atomic, Result} = mnesia:transaction(F),
  #     Result.
end
