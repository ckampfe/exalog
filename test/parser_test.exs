defmodule ParserTest do
  use ExUnit.Case
  doctest Exalog.Parser
  alias Exalog.Parser

  test "find exp" do
    query = quote do
      %{find: [artist, year, label],
        where: []}
    end

    parsed = Parser.parse(query)

    assert %Exalog.Parser.Query{
      find: %Exalog.Parser.Find{value: [
        %Exalog.Parser.Variable{value: :artist},
        %Exalog.Parser.Variable{value: :year},
        %Exalog.Parser.Variable{value: :label}
      ]},
      where: %Exalog.Parser.Where{clauses: []}
    } == parsed
  end

  test "where exp" do
    query = quote do
      %{find: [],
        where: [{entity, Album.artist, artist},
                {entity, Album.year, year},
                {entity, Album.label, label}
              ]}

    end

    parsed = Parser.parse(query)

    assert %Exalog.Parser.Query{
      find: %Exalog.Parser.Find{value: []},
      where: %Exalog.Parser.Where{clauses: [
        %Exalog.Parser.Where.Clause{
          row: :entity,
          entity: :Album,
          attribute: :artist,
          value: :artist
        },
        %Exalog.Parser.Where.Clause{
          row: :entity,
          entity: :Album,
          attribute: :year,
          value: :year
        },
        %Exalog.Parser.Where.Clause{
          row: :entity,
          entity: :Album,
          attribute: :label,
          value: :label
        }
      ]}

    } == parsed
  end
end
