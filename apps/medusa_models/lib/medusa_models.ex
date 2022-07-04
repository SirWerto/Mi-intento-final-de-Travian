defmodule MedusaModels do
  @moduledoc """
  Documentation for `MedusaModels`.
  """

  @spec apply_5d(input :: [MedusaPipeline.output()]) :: [MedusaModels.Model5D.output()]
  def apply_5d(input), do: MedusaModels.Model5D.apply(input)

  @spec apply_5d_train(input :: [MedusaPipeline.output()]) :: [
          MedusaModels.Model5D.output_train()
        ]
  def apply_5d_train(input), do: MedusaModels.Model5D.apply_train(input)
end
