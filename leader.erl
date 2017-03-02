%%% Harry Roscoe (har14) and Sahil Parekh (sp5714)

-module(leader).
-export([start/0]).

start() ->
  Ballot_num = {0, self()},
  Active = false,
  Proposals = sets:new(),
  receive
    {bind, Acceptors, Replicas} ->
      spawn(scout, start, [self(), Acceptors, Ballot_num]),
      next(Acceptors, Replicas, Ballot_num, Active, Proposals)
  end.

next(Acceptors, Replicas, Ballot_num, Active, Proposals) ->
  receive
    {propose, Slot, Command} ->
      if not slot_taken(Slot, Proposals) ->
        New_Proposals = sets:add_element({Slot, Command}, Proposals),
        if Active ->
          spawn(commander, start, [self(), Acceptors, Replicas, {Ballot_num, Slot, Command}]);
        true ->
          ok
        end,
        next(Acceptors, Replicas, Ballot_num, Active, New_Proposals);
      true ->
        next(Acceptors, Replicas, Ballot_num, Active, Proposals)
      end;

    {adopted, Ballot_num, PVals} ->
      New_Proposals = update_slots(),
      [spawn(commander, start, [self(), Acceptors, Replicas, {Ballot_num, Slot, Command}])
        || {Slot, Command} <- New_Proposals],
      New_Active = true
      next(Acceptors, Replicas, Ballot_num, New_Active, New_Proposals);

    {preempted, {R, Leader}} ->
      if {R, Leader} > Ballot_num ->
        New_Active = false,
        New_Ballot_num = {R + 1, self()},
        spawn(scout, start, [self(), Acceptors, New_Ballot_num]),
        next(Acceptors, Replicas, New_Ballot_num, New_Active, Proposals);
      true -> 
        next(Acceptors, Replicas, Ballot_num, Active, Proposals)
      end
  end.

slot_taken(Slot, Proposals) ->
  {Slots, _} = lists:unzip(sets:to_list(Proposals)),
  lists:member(Slot, Slots).

pmax()
