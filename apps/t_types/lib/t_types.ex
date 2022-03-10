defmodule TTypes do
  @moduledoc """
  `TTypes` is a source of truth for all Travian types and different definitions in `MyTravian`.
  """

  @typedoc "Server's unique identifier, it is the url of the server. The other unique identifiers use this identifier to be made."
  @type server_id :: String.t()

  @typedoc "Player's unique Travian server identifier. Collected from a map.sql snapshot."
  @type player_server_id :: String.t()

  @typedoc "Player's unique identifier. It is made by `server_id <> \"--P--\" <> player_server_id`."
  @type player_id :: String.t()

  @typedoc "Player's name. It can be modified during the server time."
  @type player_name :: String.t()

  @typedoc "Village's unique Travian server identifier. Collected from a map.sql snapshot."
  @type village_server_id :: String.t()

  @typedoc "Village's unique identifier. It is made by `server_id <> \"--V--\" <> village_server_id`."
  @type village_id :: String.t()

  @typedoc "Village's name. It can be modified during the server time."
  @type village_name :: String.t()

  @typedoc "Alliance's unique Travian server identifier. Collected from a map.sql snapshot."
  @type alliance_server_id :: String.t()

  @typedoc "Alliance's unique identifier. It is made by `server_id <> \"--A--\" <> alliance_server_id`."
  @type alliance_id :: String.t()

  @typedoc "Alliance's name. It can be modified during the server time."
  @type alliance_name :: String.t()

  @type villages_attrs_inmutable :: x() | y() | grid_position() | region()
  @type villages_attrs_mutable :: tribe() | population()

  @typedoc "Attribute related to the `village`"
  @type villages_attrs :: villages_attrs_inmutable() | villages_attrs_mutable()


  @typedoc "It's the tribe of the village. It can change if the village is conquered by another player with diffrent tribe. 
  \nIts values are: 
  \n1 => Romans
  \n2 => Teutons
  \n3 => Gauls
  \n4 => Nature
  \n5 => Natars
  \n6 => Huns
  \n7 => Egyptians"
  @type tribe :: pos_integer()

  @typedoc "Number of inhabitans who lives in the villages. It can grow if the player makes buildings and it can descend if the buildings are destroy or donwgrade. The minimun population is 1."
  @type population :: pos_integer()

  @typedoc "X position of the village."
  @type x :: integer()

  @typedoc "Y position of the village."
  @type y :: integer()

  @typedoc "Number of the field in the grid. It starts counting from the top left of the grid."
  @type grid_position :: pos_integer()


  @typedoc "If the server is type `Conquer`, this attribute defines the region where the village is."
  @type region() :: String.t()

  @typedoc "Row information in the snapshot if the server is normal."
  @type normal_snapshot_row :: {
    grid_position(),
    x(),
    y(),
    tribe(),
    village_server_id(),
    village_name(),
    player_server_id(),
    player_name(),
    alliance_server_id(),
    alliance_name(),
    population()
  }


  @typedoc "Row information in the snapshot if the server is `Conquer`."
  @type conquer_snapshot_row :: {
    grid_position(),
    x(),
    y(),
    tribe(),
    village_server_id(),
    village_name(),
    player_server_id(),
    player_name(),
    alliance_server_id(),
    alliance_name(),
    population(),
    region(),
    boolean(),
    boolean(),
    integer()
  }

  @type snapshot_row :: normal_snapshot_row() | conquer_snapshot_row()

end
