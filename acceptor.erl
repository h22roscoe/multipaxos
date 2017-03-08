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
        case B > Ballot_num of true -> B; false -> Ballot_num end,
      Scout ! {p1b, self(), Next_ballot_num, Accepted},
      next(Next_ballot_num, Accepted);

    {p2a, Commander, {B, Slot, Command}} ->
      Next_accepted =
        case B == Ballot_num of
          true ->
            Accepted ++ [{B, Slot, Command}];
          false ->
            Accepted
        end,
      Commander ! {p2b, self(), Ballot_num},
      next(Ballot_num, Next_accepted)
  end.
