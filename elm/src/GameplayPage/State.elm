module GameplayPage.State exposing (initState, update)

import Array
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

        MakeDecision accepted ->
            pure model

        ReceivedOutcome result ->
            pure model

        NextRound ->
            let
                round =
                    roundFromTransition model.transition model.options.rounds
            in
            Channel.sendRpc
                { model | transition = LoadingRound round }
                (Request.new "next_round")

        NextRoundResult result ->
            case result of
                Success dareState ->
                    pure { model | transition = Decision dareState }

                Failure error ->
                    update (Error error) model

                _ ->
                    pure model



--updateXXX : Msg -> Model -> ( Model, Cmd Msg )
--updateXXX msg model =
--    case msg of
--        NextRound ->
--            case model.transition of
--                Ready ->
--                    pure { model | transition = Decision }
--
--                Outcome _ ->
--                    pure { model | transition = Decision, round = model.round + 1 }
--
--                _ ->
--                    -- TODO: Error
--                    pure model
--
--        MakeDecision accepted ->
--            let
--                remainingSkips old =
--                    if accepted then
--                        old
--
--                    else
--                        old - 1
--            in
--            case model.transition of
--                Decision ->
--                    Channel.sendRpc
--                        { model
--                            | transition = Waiting
--                            , remainingSkips = remainingSkips model.remainingSkips
--                        }
--                        (Request.new "decision"
--                            |> Request.addBool "accept" accepted
--                        )
--
--                _ ->
--                    -- TODO: Error
--                    pure model
--
--        ReceivedOutcome result ->
--            case result of
--                Success outcome ->
--                    pure { model | transition = Outcome outcome }
--
--                _ ->
--                    -- TODO: Handle errors
--                    pure model
