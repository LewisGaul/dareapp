module GameplayPage.State exposing (initState, update)

import EnTrance.Channel as Channel
import EnTrance.Request as Request
import GameplayPage.Comms as Comms
import GameplayPage.Types exposing (Model, Msg(..), Transition(..))
import RemoteData exposing (RemoteData(..))
import Response exposing (pure)
import Types exposing (GlobalData, Options)



-- INITIAL STATE


initState : List String -> GlobalData -> Model GlobalData
initState dares globalData =
    { sendPort = Comms.gameplayPageSend
    , globalData = globalData
    , dares = dares
    , round = 0
    , remainingSkips = globalData.options.skips
    , transition = Ready
    }



-- UPDATE


{-| Handle incoming messages.
-}
update : Msg -> Model GlobalData -> ( Model GlobalData, Cmd Msg )
update msg model =
    case msg of
        NextRound ->
            case model.transition of
                Ready ->
                    pure { model | transition = Decision }

                Outcome _ ->
                    pure { model | transition = Decision, round = model.round + 1 }

                _ ->
                    -- TODO: Error
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
                Decision ->
                    Channel.sendRpc
                        { model
                            | transition = Waiting
                            , remainingSkips = remainingSkips model.remainingSkips
                        }
                        (Request.new "decision"
                            |> Request.addBool "accept" accepted
                        )

                _ ->
                    -- TODO: Error
                    pure model

        ReceivedOutcome result ->
            case result of
                Success outcome ->
                    pure { model | transition = Outcome outcome }

                _ ->
                    -- TODO: Handle errors
                    pure model
