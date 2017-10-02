defmodule Exalog.Database do
  @callback new() :: Enum.t
  @callback insert(database :: Enum.t, facts :: Enum.t) :: Enum.t
  @callback query(database :: Enum, rules :: Enum.t, query :: Enum.t) :: Enum.t
end