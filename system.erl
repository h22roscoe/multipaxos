
%%% distributed algorithms, n.dulay 27 feb 17
%%% coursework 2, paxos made moderately complex

-module(system).
-export([start/0]).

start() ->
  N_servers  = 5,
  N_clients  = 3,
  N_accounts = 10,
  Max_amount = 1000,   

  End_after  = 1000,   %  Milli-seconds for Simulation

  _Servers = [ spawn(server, start, [self(), N_accounts, End_after]) 
    || _ <- lists:seq(1, N_servers) ],
 
  Components = [ receive {config, R, A, L} -> {R, A, L} end 
    || _ <- lists:seq(1, N_servers) ],

  {Replicas, Acceptors, Leaders} = lists:unzip3(Components),

  [ Replica ! {bind, Leaders} || Replica <- Replicas ],
  [ Leader  ! {bind, Acceptors, Replicas} || Leader <- Leaders ],

  _Clients = [ spawn(client, start, 
               [Replicas, N_accounts, Max_amount, End_after])
    || _ <- lists:seq(1, N_clients) ],

  done.

