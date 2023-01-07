defmodule Collector.ServerMetadata do
  @enforce_keys [
    :server_id,
    :estimated_starting_date,
    :url
  ]

  defstruct [
    :server_id,
    :estimated_starting_date,
    :url
  ]

  @type t :: %__MODULE__{
          server_id: TTypes.server_id(),
          estimated_starting_date: Date.t(),
          url: String.t()
        }
end
