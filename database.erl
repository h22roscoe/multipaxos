
%%% distributed algorithms, n.dulay 27 feb 17
%%% coursework 2, paxos made moderately complex

-module(database).
-export([start/2]).

start(N_accounts, End_after) ->
  % add extra time for completion of all updates
  timer:send_after(End_after + 1000, finish),  

  % set all Balances to zero
  Balances = maps:from_list([ {N, 0} || N <- lists:seq(1, N_accounts) ]),

  {Balances2, Transactions} = next(Balances, 0),

  Output = [ io_lib:format("~p ~p ~p ~n", [N, maps:get(N, Balances2), self()])
             || N <- lists:seq(1, N_accounts) ],
  io:format("Transactions ~p~n~s~n", [Transactions, lists:flatten(Output)]),
  
  done.
  
next(Balances, Transactions) ->
  receive 
  {execute, {move, Amount, Account1, Account2}} ->
    Increment1 = maps:get(Account1, Balances) + Amount,
    Balances2  = Balances#{Account1 := Increment1},
    Decrement2 = maps:get(Account2, Balances2) - Amount,
    Balances3  = Balances2#{Account2 := Decrement2},
    next(Balances3, Transactions+1);
  finish -> 
    {Balances, Transactions}
  end.
