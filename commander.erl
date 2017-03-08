%%% Harry Roscoe (har14) and Sahil Parekh (sp5714)

-module(commander).
-export([start/4]).

start(Leader, Acceptors, Replicas, M) ->
  WaitFor = Acceptors,
  [A ! {p2a, self(), M} || A <- Acceptors],
  next(Leader, Acceptors, Replicas, M, WaitFor).

next(Leader, Acceptors, Replicas, {B, Slot, Command}, WaitFor) ->
  receive
    {p2b, A, NewB} ->
      case B == NewB of
        true ->
          New_WaitFor = WaitFor -- [A],
          case length(New_WaitFor) < length(Acceptors) / 2 of
            true ->
              [P ! {decision, Slot, Command} || P <- Replicas];
            false ->
              next(Leader, Acceptors, Replicas, {B, Slot, Command}, New_WaitFor)
          end;
        false ->
          Leader ! {preempted, NewB}
      end
  end.
