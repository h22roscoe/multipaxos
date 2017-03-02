%%% Harry Roscoe (har14) and Sahil Parekh (sp5714)

-module(scout).
-export([start/2]).

start(Leader, Acceptors, B) ->
  PValues = sets:new(),
  WaitFor = Acceptors,
  [Acceptor ! {p1a, self(), B} || Acceptor <- Acceptors],
  next(Leader, Acceptors, B, WaitFor, PValues).

next(Leader, Acceptors, B, WaitFor, PValues) ->
  receive
    {p1b, Acceptor, NewB, R} when B == NewB ->
      New_PValues = sets:union(PValues, R),
      New_WaitFor = WaitFor -- [Acceptor],
      if length(New_WaitFor) < length(Acceptors) / 2 ->
        Leader ! {adopted, B, New_PValues}
        ok;
      true ->
        next(Leader, Acceptors, B, New_WaitFor, New_PValues)
      end;

    {p1b, Acceptor, NewB, _} ->
      Leader ! {preempted, NewB},
      ok.
  end.
