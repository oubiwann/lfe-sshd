-module('lfe-sshd').
-behaviour(gen_server).
-define(SERVER, ?MODULE).
-define(DEFAULT_PORT, 1450).
%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/0]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

start_link() ->
    gen_server:start_link(?MODULE, [], []).

%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

init(_) ->
    Passwords = application:get_env('lfe-sshd', passwords, []),
    Port = application:get_env('lfe-sshd', port, ?DEFAULT_PORT),
    MasterApp = application:get_env('lfe-sshd', app, 'lfe-sshd'),
    PrivDir = filename:join([code:priv_dir(MasterApp), "lfe-sshd"]),
    gen_server:cast(self(), start),
    {ok, #{port => Port,
           priv_dir => PrivDir,
           passwords => Passwords,
           pid => undefined}}.

handle_call(Request, _From, State) ->
    {stop, {unimplemented, call, Request}, State}.

handle_cast(start, State = #{port := Port,
                             priv_dir := PrivDir,
                             passwords := Passwords}) ->
    {ok, Pid} = ssh:daemon(Port, [{system_dir, PrivDir},
                                  {user_dir, PrivDir},
                                  {user_passwords, Passwords},
                                  {shell, {lfe_shell, start, []}}]),
    link(Pid),
    {noreply, State#{pid => Pid}, hibernate};
handle_cast(Msg, State) ->
    {stop, {unimplemented, cast, Msg}, State}.

handle_info(Info, State) ->
    {stop, {unimplemented, info, Info}, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

