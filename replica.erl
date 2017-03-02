%%% Harry Roscoe (har14) and Sahil Parekh (sp5714)
%%% distributed algorithms, n.dulay 27 feb 17
%%% coursework 2, paxos made moderately complex

-module(replica).
-export([start/1]).

start(Database) ->
  receive
    {bind, Leaders} -> 
       next(Leaders)
  end.

next(Leaders) ->
  receive
    {request, C} ->      % request from client
      ok;
    {decision, S, C} ->  % decision from commander
      Decision = decide(S, C)
  end, % receive

  Proposal = propose(),
  ok.

propose() ->
  WINDOW = 5,
  ok.
   
decide(Database, Client) ->
  ok,
  perform(Database, Client, 1, 1),
  ok.

perform(Database, Client, Op, Cid) ->
  ok,
  Database ! {execute, Op},
  Client ! {response, Cid, ok}.

