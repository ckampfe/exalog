defmodule Exalog.InMemory do
  @behaviour Exalog.Database

  @impl true
  def new, do: []

  @impl true
  def insert(database, facts) when is_list(facts) do
    Enum.reduce(facts, database, fn(fact, db) ->
      [fact | db]
    end)
  end

  @impl true
  def query(database, rules, query) do
    database
    |> resolve_new_facts(rules)
    |> eval_query(query)
  end

  def sigil_q(var, []) do
    {:variable, var}
  end

  def resolve_new_facts(db, rules) do
    new_db = Enum.reduce(rules, db, &apply_rule/2)

    if Enum.count(db) == Enum.count(new_db) do
      db
    else
      resolve_new_facts(new_db, rules)
    end
  end

  def apply_rule(rule, db) do
    MapSet.union(
      MapSet.new(rule),
      MapSet.new(rule_as_facts(db, rule))
    )
    |> Enum.uniq
  end

  def rule_as_facts(db, rule) do
    db
    |> generate_bindings(rule)
    |> Enum.map(fn(r) ->
      substitute(rule |> List.first, r)
    end)
  end

  def substitute(query, bindings) do
    Enum.map(query, fn(identifier) ->
      unify_var(bindings, identifier)
    end)
  end

  def unify_var(bindings, identifier) do
    if variable?(identifier) do
      bindings[identifier] || identifier
    else
      identifier
    end
  end

  def variable?({:variable, identifier}), do: identifier
  def variable?(_), do: false

  def generate_bindings(facts, rule) do
    goals =
      Enum.map(rule |> Enum.drop(1), fn(query) ->
        eval_query(facts, query)
      end)

    Enum.reduce(Enum.drop(goals, 1), Enum.take(goals, 1), &unify_binding_arrays/2)
  end

  def unify_binding_arrays(val, acc) do
    Enum.flat_map(acc, fn(bindings) ->
      Enum.map(val, fn(b) ->
        unify_bindings(bindings, b)
      end)
    end)
  end

  def unify_bindings(bindings1, bindings2) do
    joined =
      Enum.reduce(bindings2, bindings1, fn(val, acc) ->
        Enum.reduce(val, acc, fn({k, v}, acc2) ->
          Map.put_new(acc2, k, v)
        end)
      end)

    other_joined =
      Enum.reduce(bindings2, bindings1, fn(val, acc) ->
        Enum.reduce(val, acc, fn({k, v}, acc2) ->
          Map.put(acc2, k, v)
        end)
      end)

    if joined == other_joined do
      joined
    end
  end

  def eval_query(facts, query) do
    matching_facts =
      Enum.flat_map(query, fn(clause) ->
        Enum.filter(facts, &unify(clause, &1))
      end)

    join_vars =
      Enum.flat_map(query, fn(clause) ->
        Enum.filter(clause, &variable?/1)
      end)
      |> Enum.group_by(fn(el) -> el end)
      |> Enum.filter(fn({_var, list}) -> Enum.count(list) > 1 end)
      |> Enum.map(fn({var, _list}) -> var end)

    case join_vars do
      # no join vars, don't do join var stuff
      [] -> Enum.map(matching_facts, &as_binding(query, &1))

      # join vars? join/group facts on the join var values of those facts
      _otherwise ->
        matching_facts
        |> Enum.map(&as_binding(query, &1))
        |> Enum.group_by(fn(binding) ->
          Enum.map(join_vars, fn(jv) ->
            Map.get(binding, jv)
          end)
        end)
        |> Enum.map(fn({_join_values, join_facts}) ->
          Enum.reduce(join_facts, %{}, fn(fact, new_facts) ->
            Map.merge(new_facts, fact)
          end)
        end)
    end
    |> Enum.uniq # this is hack, should be something like: http://docs.datomic.com/query.html#with
    |> Enum.map(&rename_vars_to_atoms/1)
  end

  def unify(query, fact) do
    unified =
      query
      |> Enum.zip(fact)
      |> Enum.all?(fn({left, right}) ->
        left == right || variable?(left) || variable?(right)
      end)

    unified
  end

  def as_binding(query, fact) do
    vars = Enum.flat_map(query, fn(clause) ->
      Enum.filter(clause, &variable?/1)
    end)

    Enum.find(query, fn(clause) ->
      unify(clause, fact)
    end)
    |> Enum.zip(fact)
    |> Enum.into(%{})
    |> Map.take(vars)
  end

  def rename_vars_to_atoms(fact) do
    Enum.map(fact, fn
      {{:variable, name}, v} -> {String.to_atom(name), v}
      value -> value
    end)
    |> Enum.into(%{})
  end
end