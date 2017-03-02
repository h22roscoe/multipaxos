%%% Harry Roscoe (har14) and Sahil Parekh (sp5714)

-module(acceptor).
-export([start/0]).

start() ->
  Ballot_num = -1,
  Accepted = [],
  next(Ballot_num, Accepted).

next(Ballot_num, Accepted) ->
  receive
    {p1a, Scout, B} ->
      Next_ballot_num =
        if B > Ballot_num ->
          B;
        true ->
          Ballot_num
        end,
      Scout ! {p1b, self(), Next_ballot_num, Accepted},
      next(Next_ballot_num, Accepted);

    {p2a, Commander, {B, Slot, Command}} ->
      Next_accepted =
        if B == Ballot_num ->
          Accepted ++ [{B, Slot, Command}];
        true ->
          Accepted
        end,
      Commander ! {p2b, self(), Ballot_num},
      next(Ballot_num, Next_accepted)
  end.
