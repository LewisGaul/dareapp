module GameplayPage.State exposing (initState, update)

import EnTrance.Channel as Channel
import EnTrance.Request as Request
import GameplayPage.Comms as Comms
import GameplayPage.Types exposing (Model, Msg(..), Transition(..), roundFromTransition)
import RemoteData exposing (RemoteData(..))
import Response exposing (pure)
import Utils.Inject as Inject
import Utils.Types exposing (Options)



-- INITIAL STATE


initState : Options -> Model
initState options =
    { sendPort = Comms.gameplayPageSend
    , options = options
    , remainingSkips = options.skips
    , transition = Ready
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Error error ->
            Inject.send (Inject.Error "gameplay page" error) model

        NextRound ->
            let
                round =
                    roundFromTransition model.transition model.options.rounds
            in
            if round == model.options.rounds then
                pure { model | transition = Finished }

            else
                Channel.sendRpc
                    { model | transition = AwaitingNextRound round }
                    (Request.new "next_round")

        NextRoundResult result ->
            case result of
                Success dareState ->
                    pure { model | transition = Decision dareState }

                Failure error ->
                    update (Error error) model

                _ ->
                    pure model

        MakeDecision accepted ->
            let
                remainingSkips old =
                    if accepted then
                        old

                    else
                        old - 1
            in
            case model.transition of
                Decision dareState ->
                    Channel.sendRpc
                        { model
                            | transition = AwaitingDecision dareState accepted
                            , remainingSkips = remainingSkips model.remainingSkips
                        }
                        (Request.new "decision"
                            |> Request.addBool "accept" accepted
                        )

                _ ->
                    update (Error "Got decision in unexpected transition phase") model

        ReceivedOutcome result ->
            case ( result, model.transition ) of
                ( Success message, AwaitingDecision dareState _ ) ->
                    pure { model | transition = Outcome dareState message }

                ( Failure error, _ ) ->
                    update (Error error) model

                ( Success _, _ ) ->
                    update (Error "Got outcome in unexpected transition phase") model

                _ ->
                    pure model



--updateXXX : Msg -> Model -> ( Model, Cmd Msg )
--updateXXX msg model =
--    case msg of
--        ReceivedOutcome result ->
--            case result of
--                Success outcome ->
--                    pure { model | transition = Outcome outcome }
--
--                _ ->
--                    -- TODO: Handle errors
--                    pure model
