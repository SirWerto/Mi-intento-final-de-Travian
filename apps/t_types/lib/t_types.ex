defmodule TTypes do
  @moduledoc """
  `TTypes` is a source of truth for all Travian types and different definitions in `MyTravian`.
  """

  @typedoc "Server's unique identifier, it is the url of the server. The other unique identifiers use this identifier to be made."
  @type server_id :: String.t()

  @typedoc "Player's unique Travian server identifier. Collected from a map.sql snapshot."
  @type player_server_id :: integer()

  @typedoc "Player's unique identifier. It is made by `server_id <> \"--P--\" <> player_server_id`."
  @type player_id :: String.t()

  @typedoc "Player's name. It can be modified during the server time."
  @type player_name :: String.t()

  @typedoc "Village's unique Travian server identifier. Collected from a map.sql snapshot."
  @type village_server_id :: integer()

  @typedoc "Village's unique identifier. It is made by `server_id <> \"--V--\" <> village_server_id`."
  @type village_id :: String.t()

  @typedoc "Village's name. It can be modified during the server time."
  @type village_name :: String.t()

  @typedoc "Alliance's unique Travian server identifier. Collected from a map.sql snapshot."
  @type alliance_server_id :: integer()

  @typedoc "Alliance's unique identifier. It is made by `server_id <> \"--A--\" <> alliance_server_id`."
  @type alliance_id :: String.t()

  @typedoc "Alliance's name. It can be modified during the server time."
  @type alliance_name :: String.t()

  @type villages_attrs_inmutable :: x() | y() | grid_position() | region()
  @type villages_attrs_mutable :: tribe_integer() | population()

  @typedoc "Attribute related to the `village`"
  @type villages_attrs :: villages_attrs_inmutable() | villages_attrs_mutable()

  @typedoc "Number of inhabitans who lives in the villages. It can grow if the player makes buildings and it can descend if the buildings are destroy or donwgrade. The minimun population is 1."
  @type population :: pos_integer()

  @typedoc "X position of the village."
  @type x :: integer()

  @typedoc "Y position of the village."
  @type y :: integer()

  @typedoc "Number of the field in the grid. It starts counting from the top left of the grid."
  @type grid_position :: pos_integer()

  @typedoc "If the server is type `Conquer`, this attribute defines the region where the village is."
  @type region() :: String.t() | nil

  @typedoc "If the server is type `Conquer`, this attribute defines the points obtained by this village."
  @type victory_points() :: pos_integer() | nil

  @typedoc "This attribute defines if the village is a capital."
  @type is_capital() :: boolean() | nil

  @typedoc "If the server is type `Conquer`, this attribute defines if the village is a city?."
  @type is_city() :: boolean() | nil

  @typedoc "Row information in the snapshot."
  @type snapshot_row :: {
          grid_position(),
          x(),
          y(),
          tribe_integer(),
          village_server_id(),
          village_name(),
          player_server_id(),
          player_name(),
          alliance_server_id(),
          alliance_name(),
          population(),
          region(),
          is_capital(),
          is_city(),
          victory_points()
        }

  @type enriched_row :: %{
          grid_position: grid_position(),
          x: x(),
          y: y(),
          tribe: tribe_integer(),
          village_id: village_server_id(),
          village_name: village_name(),
          player_id: player_server_id(),
          player_name: player_name(),
          alliance_id: alliance_server_id(),
          alliance_name: alliance_name(),
          population: population(),
          region: region(),
          is_capital: is_capital(),
          is_city: is_city(),
          victory_points: victory_points()
        }

  @typedoc "Information of the server, for example, speed."
  @type server_info :: %{String.t() => any()}



  @typedoc "It's the tribe of the player/village. It can change if the village is conquered by another player with diffrent tribe. You can check the map with `tribe_integer()` in `encode_tribe` or `decode_tribe` implementations."
  @type tribe_atom :: :romans | :teutons | :gauls | :nature | :natars | :huns | :egyptians


  @typedoc "It's the encoding of the tribe value. You can check the map with `tribe_atom()` in `encode_tribe` or `decode_tribe` implementations."
  @type tribe_integer :: pos_integer()



  @typedoc "Modification of the server_id to be used as a path."
  @type server_id_path :: binary()


  @spec encode_tribe(tribe_atom :: tribe_atom()) :: tribe_integer()
  def encode_tribe(tribe_atom) do
    case tribe_atom do
      :romans -> 1
      :teutons -> 2
      :gauls -> 3
      :nature -> 4 
      :natars -> 5
      :egyptians -> 6
      :huns -> 7
      :spartans -> 8
    end
  end

  @spec decode_tribe(tribe_int :: tribe_integer()) :: tribe_atom()
  def decode_tribe(tribe_int) do
    case tribe_int do
      1 -> :romans
      2 -> :teutons
      3 -> :gauls
      4 -> :nature
      5 -> :natars
      6 -> :egyptians
      7 -> :huns
      8 -> :spartans
    end
  end




  @spec server_id_to_path(server_id :: server_id()) :: server_id_path()
  def server_id_to_path(server_id), do: String.replace(server_id, "://", "@@")
  @spec server_id_from_path(server_id_path :: server_id_path()) :: server_id()
  def server_id_from_path(server_id_path), do: String.replace(server_id_path, "@@", "://")
end
