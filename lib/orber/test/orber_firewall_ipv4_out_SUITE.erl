%%
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 2004-2010. All Rights Reserved.
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

-module(orber_firewall_ipv4_out_SUITE).

-include("test_server.hrl").
-include_lib("orber/include/corba.hrl").
-include_lib("orber/COSS/CosNaming/CosNaming.hrl").
-include_lib("orber/src/orber_iiop.hrl").
-include_lib("orber/src/ifr_objects.hrl").
-include("idl_output/orber_test_server.hrl").
-include_lib("orber/COSS/CosNaming/CosNaming_NamingContextExt.hrl").
-include_lib("orber/COSS/CosNaming/CosNaming_NamingContext.hrl").

-define(default_timeout, ?t:minutes(15)).

-define(match(ExpectedRes,Expr),
	fun() ->
		AcTuAlReS = (catch (Expr)),
		case AcTuAlReS of
		    ExpectedRes ->
			io:format("------ CORRECT RESULT ------~n~p~n",
				 [AcTuAlReS]),
			AcTuAlReS;
		    _ ->
			io:format("###### ERROR ERROR ######~nRESULT:  ~p~n",
				  [AcTuAlReS]),
			?line exit(AcTuAlReS)
		end
	end()).

%%-----------------------------------------------------------------
%% External exports
%%-----------------------------------------------------------------
-export([all/1, cases/0, init_all/1, finish_all/1, 
	 init_per_testcase/2, end_per_testcase/2,  
	 deny_port_api/1, deny_port_range_api/1, deny_host_api/1,
	 allow_port_api/1, allow_port_range_api/1, allow_host_api/1,
	 local_interface_api/1]).

%%-----------------------------------------------------------------
%% Func: all/1
%% Args: 
%% Returns: 
%%-----------------------------------------------------------------
all(doc) -> ["API tests for orber's firewall functionallity."];
all(suite) -> {req,
               [mnesia],
               {conf, init_all, cases(), finish_all}}.

%% NOTE - the fragment test cases must bu first since we explicitly set a request
%% id. Otherwise, the request-id counter would be increased and we cannot know
%% what it is.
cases() ->
    [deny_port_api, deny_port_range_api, deny_host_api,
     allow_port_api, allow_port_range_api, allow_host_api,
     local_interface_api].


init_per_testcase(_Case, Config) ->
    ?line Dog=test_server:timetrap(?default_timeout),
    [{watchdog, Dog}|Config].


end_per_testcase(_Case, Config) ->
    Dog = ?config(watchdog, Config),
    test_server:timetrap_cancel(Dog),
    ok.

init_all(Config) ->
    if
	is_list(Config) ->
	    orber:jump_start([{iiop_port, 0},
			      {iiop_out_ports, {5980, 6000}}]),
	    Config;
	true ->
	    exit("Config not a list")
    end.

finish_all(Config) ->
    orber:jump_stop(),
    Config.

%%-----------------------------------------------------------------
%%  Incomming connections - Deny
%%-----------------------------------------------------------------
deny_port_api(doc) -> ["Deny Access due to invalid local port"];
deny_port_api(suite) -> [];
deny_port_api(_Config) ->
    [IP] = ?match([_], orber:host()),
    ServerPort = orber:iiop_port(),
    {ok, ClientNode, _ClientHost} = 
	?match({ok,_,_}, orber_test_lib:js_node([{flags, ?ORB_ENV_USE_ACL_OUTGOING},
						 {iiop_acl, [{tcp_out, IP++"/32#" ++ integer_to_list(ServerPort+10)}]}])),
    ?match({'EXCEPTION', #'CosNaming_NamingContextExt_InvalidAddress'{}}, 
	   orber_test_lib:remote_apply(ClientNode, corba, string_to_object, 
	   ["corbaloc::1.2@"++IP++":"++integer_to_list(ServerPort)++"/NameService"])),
%    ?line catch orber_test_lib:destroy_node(ClientNode, timeout),
    ok.

deny_port_range_api(doc) -> ["Deny Access due to invalid local port range"];
deny_port_range_api(suite) -> [];
deny_port_range_api(_Config) ->
    [IP] = ?match([_], orber:host()),
    ServerPort = orber:iiop_port(),
    {ok, ClientNode, _ClientHost} = 
	?match({ok,_,_}, orber_test_lib:js_node([{flags, ?ORB_ENV_USE_ACL_OUTGOING},
						 {iiop_acl, [{tcp_out, IP++"/32#"++integer_to_list(ServerPort+100)++ "/" ++ integer_to_list(ServerPort+120)}]}])),
    ?match({'EXCEPTION', #'CosNaming_NamingContextExt_InvalidAddress'{}}, 
	   orber_test_lib:remote_apply(ClientNode, corba, string_to_object, 
				       ["corbaloc::1.2@"++IP++":"++integer_to_list(ServerPort)++"/NameService"])),
%    ?line catch orber_test_lib:destroy_node(ClientNode, timeout),
    ok.


deny_host_api(doc) -> ["Deny Access due to invalid host"];
deny_host_api(suite) -> [];
deny_host_api(_Config) ->
    [IP] = ?match([_], orber:host()),
    {ok, ClientNode, _ClientHost} = 
	?match({ok,_,_}, orber_test_lib:js_node([{flags, ?ORB_ENV_USE_ACL_OUTGOING},
						 {iiop_acl, [{tcp_out, "123.123.123.123/32"}]}])),
    ServerPort = orber:iiop_port(),
    ?match({'EXCEPTION', #'CosNaming_NamingContextExt_InvalidAddress'{}}, 
	   orber_test_lib:remote_apply(ClientNode, corba, string_to_object, 
				       ["corbaloc::1.2@"++IP++":"++integer_to_list(ServerPort)++"/NameService"])),
%    ?line catch orber_test_lib:destroy_node(ClientNode, timeout),
    ok.

%%-----------------------------------------------------------------
%%  Incomming connections - Allow
%%-----------------------------------------------------------------
allow_port_api(doc) -> ["Allow Access due to valid local port range"];
allow_port_api(suite) -> [];
allow_port_api(_Config) ->
    [IP] = ?match([_], orber:host()),
    ServerPort = orber:iiop_port(),
    {ok, ClientNode, _ClientHost} = 
	?match({ok,_,_}, orber_test_lib:js_node([{flags, ?ORB_ENV_USE_ACL_OUTGOING},
						 {iiop_acl, [{tcp_out, IP++"/32#"++integer_to_list(ServerPort)}]}])),
    IOR =
	?match({'IOP_IOR',_,_},
	       orber_test_lib:remote_apply(ClientNode, corba, string_to_object, 
					   ["corbaloc::1.2@"++IP++":"++integer_to_list(ServerPort)++"/NameService"])),
    ?match(false, 
	   orber_test_lib:remote_apply(ClientNode, corba_object, not_existent, [IOR])),
%    ?line catch orber_test_lib:destroy_node(ClientNode, timeout),
    ok.

allow_port_range_api(doc) -> ["Allow Access due to valid local port range"];
allow_port_range_api(suite) -> [];
allow_port_range_api(_Config) ->
    [IP] = ?match([_], orber:host()),
    ServerPort = orber:iiop_port(),
    {ok, ClientNode, _ClientHost} = 
	?match({ok,_,_}, orber_test_lib:js_node([{flags, ?ORB_ENV_USE_ACL_OUTGOING},
						 {iiop_acl, [{tcp_out, IP++"/32#" ++ integer_to_list(ServerPort-10) ++ "/" ++ integer_to_list(ServerPort+10)}]}])),
    IOR = 
	?match({'IOP_IOR',_,_},
	       orber_test_lib:remote_apply(ClientNode, corba, string_to_object, 
					   ["corbaloc::1.2@"++IP++":"++integer_to_list(ServerPort)++"/NameService"])),
    ?match(false, 
	   orber_test_lib:remote_apply(ClientNode, corba_object, not_existent, [IOR])),
%    ?line catch orber_test_lib:destroy_node(ClientNode, timeout),
    ok.


allow_host_api(doc) -> ["Allow Access due to valid host"];
allow_host_api(suite) -> [];
allow_host_api(_Config) ->
    [IP] = ?match([_], orber:host()),
    {ok, ClientNode, _ClientHost} = 
	?match({ok,_,_}, orber_test_lib:js_node([{flags, ?ORB_ENV_USE_ACL_OUTGOING},
						 {iiop_acl, [{tcp_out, IP++"/32"}]}])),
    ServerPort = orber:iiop_port(),
    IOR =
	?match({'IOP_IOR',_,_}, 
	       orber_test_lib:remote_apply(ClientNode, corba, string_to_object, 
					   ["corbaloc::1.2@"++IP++":"++integer_to_list(ServerPort)++"/NameService"])),
    ?match(false, 
	   orber_test_lib:remote_apply(ClientNode, corba_object, not_existent, [IOR])),
%    ?line catch orber_test_lib:destroy_node(ClientNode, timeout),
    ok.

local_interface_api(doc) -> ["Allow Access due to valid host via a spcific interface"];
local_interface_api(suite) -> [];
local_interface_api(_Config) ->
    IP = orber_test_lib:get_host(),
    Loopback = orber_test_lib:get_loopback_interface(),
    {ok, ServerNode, _ServerHost} = 
	?match({ok,_,_}, orber_test_lib:js_node([{iiop_port, 0},
						 {iiop_out_ports, {5980, 6000}},
						 {ip_address, IP}])),
    ServerPort = orber_test_lib:remote_apply(ServerNode, orber, iiop_port, []),

    {ok, ClientNode, _ClientHost} = 
	?match({ok,_,_}, orber_test_lib:js_node([{flags, ?ORB_ENV_USE_ACL_OUTGOING},
						 {iiop_acl, [{tcp_out, IP, [Loopback]}]}])),
    IOR =
	?match({'IOP_IOR',_,_}, 
	       orber_test_lib:remote_apply(ClientNode, corba, string_to_object, 
					   ["corbaloc::1.2@"++IP++":"++integer_to_list(ServerPort)++"/NameService"])),
    ?match(false, 
	   orber_test_lib:remote_apply(ClientNode, corba_object, not_existent, [IOR])),
%    ?line catch orber_test_lib:destroy_node(ClientNode, timeout),
    ok.

