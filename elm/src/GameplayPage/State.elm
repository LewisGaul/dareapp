module GameplayPage.State exposing (initState, update)

import GameplayPage.Comms as Comms
import GameplayPage.Types exposing (Model, Msg(..), Transition(..))
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
        NextRound refused ->
            let
                remainingSkips old =
                    if refused then
                        old - 1

                    else
                        old
            in
            case model.transition of
                Ready ->
                    pure { model | transition = Decision }

                Decision ->
                    -- TODO: Error
                    pure model

                _ ->
                    if model.round + 1 < model.globalData.options.rounds then
                        pure
                            { model
                                | transition = Decision
                                , round = model.round + 1
                                , remainingSkips = remainingSkips model.remainingSkips
                            }

                    else
                        pure { model | transition = Finished }
