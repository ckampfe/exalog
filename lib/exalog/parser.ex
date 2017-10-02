defmodule Exalog.Parser do
#   query                      = [find-spec with-clause? inputs? where-clauses?]
# find-spec                  = ':find' (find-rel | find-coll | find-tuple | find-scalar)
# find-rel                   = find-elem+
# find-coll                  = [find-elem '...']
# find-scalar                = find-elem '.'
# find-tuple                 = [find-elem+]
# find-elem                  = (variable | pull-expr | aggregate)


  defmodule Query do
    defstruct [:find, :where]
  end

  defmodule Find do
    defstruct [:value]
  end

  defmodule Variable do
    defstruct [:value]
  end

  defmodule Where do
    defstruct [:clauses]

    defmodule Clause do
      defstruct [:row, :entity, :attribute, :value]
    end
  end

  def parse({:%{}, [], body} = query) do
    body = Enum.into(body, %{})

    find = parse_find(body)
    where = parse_where(body)


    %Query{
      find: find,
      where: where
    }
  end

  def parse_find(%{find: find}) do
    vars =
      find
      |> Enum.map(fn({var, _, _}) when is_atom(var) ->
        %Variable{value: var}
      end)

    %Find{value: vars}
  end

  def parse_where(%{where: where}) do
    clauses =
      where
      |> Enum.map(fn({:{}, [],
                      [{row, [], _},
                       {{:., [], [{:__aliases__, _, [entity]}, attribute]}, [], []},
                       {value, [], _}]}) ->

        %Where.Clause{
          row: row,
          entity: entity,
          attribute: attribute,
          value: value
        }
      end)

    %Where{clauses: clauses}
  end
end
