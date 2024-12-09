-module(glm_temp_eff).

-export([buffer_testing/1]).

% -define(wrapstr(T), "\"" ++ T ++ "\"").
% -define(cama, ",").

% -define(red, "\e[31;1m").
% -define(grey, "\e[90m").
% -define(reset_color, "\e[39m").
% -define(reset_all, "\e[0m").

% https://erlangforums.com/t/how-to-evaluate-expressions-containing-record-reference/3273/6
buffer_testing({templ, Statments} = Fragments) when is_tuple(Fragments) ->
    test().
% % OutBuffer@0 = [],
% Bindings = erl_eval:new_bindings(),
% % Bindings@1 = erl_eval:add_binding('Red', ?red, Bindings),
% io:format("~p~n", [
%     Statments
% ]),
% Source =
%     % "try"
%     "\nOutBuffer=[],"
%     "gleam@string:join(OutBuffer,\"\").",
% % "catch"
% % "   Class:Reason:StackTrace ->"
% % "io:format(\"~p~n\", [StackTrace]),"
% % "   io:format(\"~ts~n\", [["
% % ?wrapstr(?red)
% % ?cama
% % ?wrapstr("Error: ")
% % ?cama
% % ?wrapstr(?reset_color)
% % ?cama
% % "atom_to_binary(Reason)"
% % ?cama
% % "[Line || Line <- StackTrace]"
% % ?cama
% % ?wrapstr(?reset_all)
% % "]])"
% % "   io:format(\"~p~n\", [StackTrace])"
% % "   init:stop(1)"
% % "   _:_:_ ->  io_lib:format(\"~p\", [6])"
% % "end."

% {ErlAbForm, Value, _NewBindings} = eval_exprs(
%     Source,
%     Bindings
% ),
% io:format("~p~n", [
%     {ErlAbForm}
% ]),
% io:format("\n\n~p~n", [
%     {Value}
% ]),
% % io:format("\n~p~n", [
% %     Statments
% % ]),
% "".

eval_exprs(Source, Bindings) ->
    %% Parse the expression
    {ok, Tokens, _} = erl_scan:string(Source),
    {ok, Exprs} = erl_parse:parse_exprs(Tokens),
    %% Evaluate the expression
    case erl_eval:exprs(Exprs, Bindings) of
        {value, Value, NewBindings} -> {Exprs, Value, NewBindings};
        Error -> Error
    end.

% Note using this just for testing and thinking out
% how the code will be compiled
test() ->
    fun(Data) when is_map(Data) ->
        io:format("~p~n", [Data]),
        OutBuff@0 = [],
        Globals@0 = #{data => Data},
        OutBuff@1 =
            OutBuff@0 ++
                [
                    % gleam equavalent would be scoping it to `{}` block
                    % however it is expected to return `String`
                    begin
                        gleam@int:to_string(1)
                    end
                    % , begin
                    %   % if <cond> {} else {}
                    %       case <cond> of
                    %           False -> ..
                    %           True -> ..
                    %       end
                    %   end
                ],
        % logic tag

        % logic affects global scope
        % let decloration... (test)
        {OutBuff@2, Globals@1} = begin
            % code:
            % let name = data.name
            % echo("Echoed")
            % echo(" Echoed again")
            {Global_New, Echoed_out, _Echoed_Unsafe_out} = (fun(G@) ->
                InnerG_@0 = G@,
                Echo_Buff@0 = [],
                Echo_Unsafe_Buff@0 = [],
                % In gleam types this is expected to return `Nil` always
                % to output text (which is not recommended) you can use `echo([...])`
                % echo -> fn(List(String)) -> Nil

                % let name = data.name
                Name = map_get(<<"name">>, map_get(data, InnerG_@0)),
                % insert assigment to globals returned
                InnerG_@1 = maps:merge(InnerG_@0, #{name => Name}),

                % % quick if for gleam--output is also ignored
                % _ =
                %     case false of
                %         _ -> nil
                %     end,

                % Echo([Name]),
                Echo_Buff@1 = Echo_Buff@0 ++ [Name],
                % Echo([<<" Echoed">>]),
                Echo_Buff@2 = Echo_Buff@1 ++ [<<" Echoed">>],
                % Echo([<<" Echoed again">>]),
                Echo_Buff@3 = Echo_Buff@2 ++ [<<" Echoed">>],
                {InnerG_@1, Echo_Buff@3, Echo_Unsafe_Buff@0}
            end)(
                Globals@0
            ),
            % io:format("~p~n", [Echoed_out]),
            Echo_out = lists:flatten(Echoed_out),

            {OutBuff@1 ++ [gleam@string:join(Echo_out, "")], Global_New}
        end,
        io:format("~p~n", [Globals@1]),

        gleam@string:join(OutBuff@2, "")
    end.

-spec erlang_source_to_af(Source) -> Return when
    Return ::
        {ok, erl_parse:abstract_expr()}
        | {error, {some, erl_scan:error_info()}}
        | {error, none},
    Source :: string().

erlang_source_to_af(Source) when is_binary(Source) ->
    {ok, Tokens, _} = erl_scan:string(Source),
    {ok, Exprs} = erl_parse:parse_exprs(Tokens),
    {error, none}.
