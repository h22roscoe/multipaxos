
%%% distributed algorithms, n.dulay 27 feb 17
%%% coursework 2, paxos made moderately complex

-module(client).
-export([start/4]).

start(Replicas, N_accounts, Max_amount, End_after) ->
  timer:send_after(End_after, finish),
  next(Replicas, N_accounts, Max_amount, 0).

next(Replicas, N_accounts, Max_amount, Cid) ->
  % Warning removing sleep will completely overload the system 
  % with large numbers of requests and spawned processes. 
  % Increase the timeout in database significantly to ensure 
  % all updates are done.
  % [ erlang:yield() || _N <- lists:seq(1, 100) ],
  timer:sleep(1), 

  Account1 = rand:uniform(N_accounts),
  Account2 = rand:uniform(N_accounts),
  Amount   = rand:uniform(Max_amount),
  Op   = {move, Amount, Account1, Account2},
  Cid2 = Cid + 1,
  Cmd  = {self(), Cid2, Op},

  [ Replica ! {request, Cmd} || Replica <- Replicas ],

  ignore_responses(),

  receive
    finish  -> finish  
    after 0 -> next(Replicas, N_accounts, Max_amount, Cid2)
  end.
    
ignore_responses() ->
  receive 
    {response, _Result} -> ignore_responses()
    after 0 -> return
  end.

