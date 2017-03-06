%%% Harry Roscoe (har14) and Sahil Parekh (sp5714)
%%% distributed algorithms, n.dulay 27 feb 17
%%% coursework 2, paxos made moderately complex

-module(replica).
-export([start/1]).

start(Database) ->
  Slot_In = 1,
  Slot_Out = 1,
  Requests = sets:new(),
  Proposals = sets:new(),
  Decisions = sets:new(),
  receive
    {bind, Leaders} ->
       next(Leaders, Slot_In, Slot_Out, Requests, Proposals, Decisions, Database)
  end.

next(Leaders, Slot_In, Slot_Out, Requests, Proposals, Decisions, Database) ->
  receive
    {request, C} -> % request from client
      N_Requests = sets:add_element(C, Requests),
      N_Decisions = Decisions,
      N_Proposals = Proposals,
      N_Slot_Out = Slot_Out;
    {decision, S, C} ->  % decision from commander
      N_Decisions = sets:add_element({S, C}, Decisions),
      Slot_Out_Ds = sets:filter(fun({Slot, _}) -> Slot == Slot_Out end, N_Decisions),
      Slot_Out_Ps = sets:filter(fun({Slot, _}) -> Slot == Slot_Out end, Proposals),
      {N_Proposals, N_Requests, N_Slot_Out} = decide(S, C, Slot_Out_Ds, Slot_Out_Ps, Requests, Database, Slot_Out)
  end, % receive

  {N_Slot_In, N_N_Requests, N_N_Proposals} = propose(Leaders, Slot_In, N_Slot_Out, N_Requests, N_Proposals, Decisions),
  next(Leaders, N_Slot_In, N_Slot_Out, N_N_Requests, N_N_Proposals, N_Decisions, Database).

propose(Leaders, Slot_In, Slot_Out, Requests, Proposals, Decisions) ->
  WINDOW = 5,
  Len = sets:size(Requests),
  if (Slot_In < (Slot_Out + WINDOW)) and (Len > 0) ->
    [C | Rest] = sets:to_list(Requests),
    % Split decision into list so that we can check if there is not one with
    % the Slot_In
    {Slots, _} = lists:unzip(sets:to_list(Decisions)),
    Slot_In_in_Slots = sets:is_element(Slot_In, sets:from_list(Slots)),
    if not Slot_In_in_Slots ->
      N_Requests = sets:from_list(Rest),
      N_Proposals = sets:add_element({Slot_In, C}, Proposals),
      [Leader ! {propose, Slot_In, C} || Leader <- Leaders];
    true ->
      N_Requests = Requests,
      N_Proposals = Proposals
    end,
    N_Slot_In = Slot_In + 1,
    propose(Leaders, N_Slot_In, Slot_Out, N_Requests, N_Proposals, Decisions);
  true -> {Slot_In, Requests, Proposals}
  end.

decide(S, C, Decisions, Proposals, Requests, Database, Slot_Out) ->
  Len_Ds = sets:size(Decisions),
  Len_Ps = sets:size(Proposals),

  % Check there are more decisions to loop through
  if Len_Ds > 0 ->
    [{_, CPrime} | Rest] = sets:to_list(Decisions),
    % And check there is exists a proposal within Slot_Out_Ps
    if Len_Ps > 0 ->
      [{S_Out, CPrimePrime} | _] = sets:to_list(Proposals),
      N_Proposals = sets:del_element({S_Out, CPrimePrime}, Proposals),
      if CPrimePrime /= CPrime ->
        N_Requests = sets:add_element(CPrimePrime, Requests);
      true ->
        N_Requests = Requests
      end;
    true ->
      N_Proposals = Proposals,
      N_Requests = Requests
    end,
    N_Slot_Out = perform(Database, C),
    % Loop around with new values
    decide(S, C, Rest, N_Proposals, N_Requests, Database, N_Slot_Out);

  % End loop
  true ->
    {Proposals, Requests, Slot_Out}
  end.

perform(Database, {Client, Op, Cid}) ->
  Database ! {execute, Op},
  Client ! {response, Cid, ok}.
