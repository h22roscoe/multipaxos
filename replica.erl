%%% Harry Roscoe (har14) and Sahil Parekh (sp5714)
%%% distributed algorithms, n.dulay 27 feb 17
%%% coursework 2, paxos made moderately complex

-module(replica).
-export([start/1]).

start(Database) ->
  Slot_In = 1,
  Slot_Out = 1,
  Requests = [],
  Proposals = [],
  Decisions = [],
  receive
    {bind, Leaders} ->
       next(Leaders, Slot_In, Slot_Out, Requests, Proposals, Decisions, Database)
  end.

next(Leaders, Slot_In, Slot_Out, Requests, Proposals, Decisions, Database) ->
  receive
    {request, C} -> % request from client
      N_Requests = [C] ++ Requests,
      N_Decisions = Decisions,
      N_Proposals = Proposals,
      N_Slot_Out = Slot_Out;
    {decision, S, C} ->  % decision from commander
      N_Decisions = [{S, C}] ++ Decisions,
      Slot_Out_Ds =
        lists:filter(fun({Slot, _}) -> Slot == Slot_Out end, N_Decisions),
      {Slot_Out_Ps, Others} =
        lists:partition(fun({Slot, _}) -> Slot == Slot_Out end, Proposals),
      {N_Props, N_Requests, N_Slot_Out} =
        decide(S, C, Slot_Out_Ds, Slot_Out_Ps, Requests, Database, Slot_Out),
      N_Proposals = N_Props ++ Others
  end, % receive

  {N_Slot_In, N_N_Requests, N_N_Proposals} =
    propose(Leaders, Slot_In, N_Slot_Out, N_Requests, N_Proposals, Decisions),
  next(Leaders, N_Slot_In, N_Slot_Out, N_N_Requests, N_N_Proposals, N_Decisions, Database).

propose(Leaders, Slot_In, Slot_Out, Requests, Proposals, Decisions) ->
  WINDOW = 5,
  Len = length(Requests),
  if (Slot_In < (Slot_Out + WINDOW)) and (Len > 0) ->
    [C | Rest] = Requests,
    % Split decision into list so that we can check if there is not one with
    % the Slot_In
    {Slots, _} = lists:unzip(Decisions),
    Slot_In_in_Slots = lists:member(Slot_In, Slots),
    case not Slot_In_in_Slots of
      true ->
        N_Requests = Rest,
        N_Proposals = [{Slot_In, C}] ++ Proposals,
        [Leader ! {propose, Slot_In, C} || Leader <- Leaders];
      false ->
        N_Requests = Requests,
        N_Proposals = Proposals
    end,
    N_Slot_In = Slot_In + 1,
    propose(Leaders, N_Slot_In, Slot_Out, N_Requests, N_Proposals, Decisions);
  true -> {Slot_In, Requests, Proposals}
  end.

decide(S, C, Decisions, Proposals, Requests, Database, Slot_Out) ->
  Len_Ds = length(Decisions),
  Len_Ps = length(Proposals),

  % Check there are more decisions to loop through
  if Len_Ds > 0 ->
    [{_, CPrime} | Rest] = Decisions,
    % And check there is exists a proposal within Slot_Out_Ps
    if Len_Ps > 0 ->
      [{S_Out, CPrimePrime} | _] = Proposals,
      N_Proposals = Proposals -- [{S_Out, CPrimePrime}],
      N_Requests =
        if CPrimePrime /= CPrime ->
          [CPrimePrime] ++ Requests;
        true ->
          Requests
        end;
    true ->
      N_Proposals = Proposals,
      N_Requests = Requests
    end,
    N_Slot_Out = perform(Database, C, Decisions, Slot_Out),
    % Loop around with new values
    decide(S, C, Rest, N_Proposals, N_Requests, Database, N_Slot_Out);
  % End loop
  true ->
    {Proposals, Requests, Slot_Out}
  end.

perform(Database, {Client, Op, Cid}, Decisions, Slot_Out) ->
  Lower_Slot_In_Decs =
    lower_slot_in_decs(Slot_Out, {Client, Op, Cid}, Decisions),
  N_Slot_Out = if Lower_Slot_In_Decs -> Slot_Out + 1; true -> Slot_Out end,
  Database ! {execute, Op},
  N_N_Slot_Out = N_Slot_Out + 1,
  Client ! {response, Cid, ok},
  N_N_Slot_Out.

lower_slot_in_decs(Slot_Out, Command, Decisions) ->
  length([{S, C} || {S, C} <- Decisions, S < Slot_Out, C == Command]) > 0.
