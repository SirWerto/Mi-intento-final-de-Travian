defmodule Satellite.MedusaTable do
  require Record

  @table_name :medusa_table

  # @medusa_record {:medusa_row, :server_id, :server_url, :player_id, :player_name, :player_url,
  #                 :alliance_id, :alliance_name, :alliance_url, :inactive_in_future,
  #                 :inactive_in_current, :total_population, :model, :n_villages, :target_date,
  #                 :creation_dt}

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
          inactive_in_future: boolean() | :undefined,
          inactive_in_current: boolean(),
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

  @spec get_predictions_by_server(server_id :: TTypes.server_id()) :: :ok
  def get_predictions_by_server(server_id) do
    pattern = {@table_name, :_, server_id, :_}

    func = fn -> :mnesia.match_object(pattern) end
    for res <- :mnesia.activity(:transaction, func), do: elem(res, 3)
  end

  # @spec add_players([{binary(), binary(), binary(), binary(), integer(), integer()}])
  #  :: {:atomic, any()} | {:aborted, any()}
  #  def add_players(players) do
  #    func = fn -> for player <- players, do: :mnesia.write(make_record_from_player(player)) end
  #    :mnesia.activity(:transaction, func)
  #  end

  # @spec record_from_struct(x :: t()) :: tuple()
  # defp record_from_struct(x) do
  #   {@table_name,
  #   x.player_id,
  #   x.player_name,
  #   x.player_url,
  #   x.server_id,
  #   x.server_url,
  #   x.alliance_id,
  #   x.alliance_name,
  #   x.alliance_url,
  #   x.inactive_in_future,
  #   x.inactive_in_current,
  #   x.total_population,
  #   x.model,
  #   x.n_villages,
  #   x.target_date,
  #   x.creation_dt
  #   }
  # end
end
