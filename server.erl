
%%% distributed algorithms, n.dulay 27 feb 17
%%% coursework 2, paxos made moderately complex

-module(server).
-export([start/3]).

start(System, N_accounts, End_after) ->

  Database = spawn(database, start, [N_accounts, End_after]),

  Replica = spawn(replica, start, [Database]),

  Leader = spawn(leader, start, []),

  Acceptor = spawn(acceptor, start, []),

  System ! {config, Replica, Acceptor, Leader},

  done.

