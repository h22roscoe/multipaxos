%%% Harry Roscoe (har14) and Sahil Parekh (sp5714)

-module(leader).
-export([start/0]).

start() ->
  Ballot_num = {0, self()},
  Active = false,
  Proposals = [],
  receive
    {bind, Acceptors, Replicas} ->
      spawn(scout, start, [self(), Acceptors, Ballot_num]),
      next(Acceptors, Replicas, Ballot_num, Active, Proposals)
  end.

next(Acceptors, Replicas, Ballot_num, Active, Proposals) ->
  receive
    {propose, Slot, Command} ->
      Taken = slot_taken(Slot, Proposals),
      case not Taken of
        true ->
          New_Proposals = [{Slot, Command}] ++ Proposals,
          case Active of
            true ->
              spawn(commander, start, [self(), Acceptors, Replicas, {Ballot_num, Slot, Command}]);
            false ->
              ok
          end,
          next(Acceptors, Replicas, Ballot_num, Active, New_Proposals);
        false ->
          next(Acceptors, Replicas, Ballot_num, Active, Proposals)
      end;

    {adopted, Ballot_num, PVals} ->
      New_Proposals = triangle(Proposals, pmax(PVals)),
      [spawn(commander, start, [self(), Acceptors, Replicas, {Ballot_num, Slot, Command}])
        || {Slot, Command} <- New_Proposals],
      New_Active = true,
      next(Acceptors, Replicas, Ballot_num, New_Active, New_Proposals);

    {preempted, {R, Leader}} ->
      case {R, Leader} > Ballot_num of
        true ->
          New_Active = false,
          New_Ballot_num = {R + 1, self()},
          spawn(scout, start, [self(), Acceptors, New_Ballot_num]),
          next(Acceptors, Replicas, New_Ballot_num, New_Active, Proposals);
        false ->
          next(Acceptors, Replicas, Ballot_num, Active, Proposals)
      end
  end.

slot_taken(Slot, Proposals) ->
  {Slots, _} = lists:unzip(Proposals),
  lists:member(Slot, Slots).

pmax(PVals) ->
  % Get the biggest ballot numbers first and then take while slot not in list
  Sorted = lists:usort(fun({B1, S1, _}, {B2, S2, _}) -> (S1 == S2) and (B1 > B2) end, PVals),
  [{S, C} || {_, S, C} <- Sorted].

triangle(X, Y) ->
  sets:to_list(sets:from_list(Y ++ (X -- Y))).
