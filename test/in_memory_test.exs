defmodule InMemoryTest do
  use ExUnit.Case
  doctest Exalog.InMemory
  alias Exalog.InMemory
  import Exalog.InMemory, only: [sigil_q: 2]

  test "creates a db" do
    assert [] == InMemory.new()
  end

  test "inserts facts" do
    assert (
      [[:artist, :name, "outkast"],
       [:artist, :albums, ["aquemini", "stankonia"]]] |> MapSet.new
    ) == (InMemory.new |> InMemory.insert(
      [[:artist, :name, "outkast"],
       [:artist, :albums, ["aquemini", "stankonia"]]]
    ) |> MapSet.new)

    assert (
      [[:artist, :name, "outkast"],
       [:artist, :albums, ["aquemini", "stankonia"]]] |> MapSet.new
    ) == (InMemory.new |> InMemory.insert(
      [[:artist, :name, "outkast"],
       [:artist, :albums, ["aquemini", "stankonia"]]]
    ) |> MapSet.new)
  end

  test "queries" do
    db =
      InMemory.new
      |> InMemory.insert(
        [["outkast", :members, 2],
         ["outkast", :albums, ["aquemini", "stankonia"]],
         ["motorhead", :members, "lemmy"]
        ])

    assert [%{name: "motorhead"},
            %{name: "outkast"}
            ] == InMemory.query(
      db,
      [],
      [[~q(name)]]
    )

    assert [%{albums: ["aquemini", "stankonia"]}] == InMemory.query(
      db,
      [],
      [["outkast", :albums, ~q(albums)]]
    )

    assert [%{members: 2},
            %{albums: ["aquemini", "stankonia"]}] == InMemory.query(
      db,
      [],
      [["outkast", :members, ~q(members)],
       ["outkast", :albums, ~q(albums)]]
    )

    assert [%{artist: "motorhead",
              members: "lemmy"},
            %{artist: "outkast",
              members: 2,
              albums: ["aquemini", "stankonia"]}] == InMemory.query(
      db,
      [],
      [[~q(artist), :members, ~q(members)],
       [~q(artist), :albums, ~q(albums)]]
    )
  end
end