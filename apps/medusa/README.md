# Medusa

## Function
This app performs and ETL over the data collected from Travian and predicts if a player is going to keep playing or not.

## Events
In order to receive events, you need to subscribe to it
```elixir
Medusa.subscribe()

{:medusa_event, :predictions_started}
{:medusa_event, :predictions_finished}
```


## Architecture

[Medusa arch](./imgs/medusa_arch.png)
