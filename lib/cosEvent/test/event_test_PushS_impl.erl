%%------------------------------------------------------------------------
%%
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 2001-2009. All Rights Reserved.
%% 
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%% 
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%% 
%% %CopyrightEnd%
%%
%%
%%------------------------------------------------------------------------
%% Description: a very simple implementation of Push Supplier interface
%%------------------------------------------------------------------------
 
-module(event_test_PushS_impl).
 
-export([init/1, terminate/2, disconnect_push_supplier/1, do_push/2]).
 
init(Proxy) ->
        {ok, Proxy}.
 
terminate(_From, _Reason) ->
    ok.

disconnect_push_supplier(Proxy) ->
    io:format("event_test_PullC terminates~n",[]),
    {stop, normal, ok, Proxy}.

do_push(Proxy, Event) ->
    {reply, 'CosEventComm_PushConsumer':push(Proxy, Event), Proxy}.

