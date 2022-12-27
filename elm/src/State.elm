module State exposing (defaultOptions, init, update)

import Array
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Comms
import EnTrance.Channel as Channel
import EnTrance.Request as Request
import EntryPage.State
import EntryPage.Types
import GameplayPage.State
import RemoteData exposing (RemoteData(..))
import Response exposing (pure)
import Types exposing (GlobalData, Model, Msg(..), Options, Phase(..))
import Url
import Url.Parser as Parser
import UrlParser exposing (urlParser)



-- INITIAL STATE


defaultOptions : Options
defaultOptions =
    { players = 2, rounds = 10, skips = 5 }


init : { basePath : String } -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init { basePath } url navKey =
    pure
        { sendPort = Comms.appSend
        , lastError = Nothing
        , basePath = basePath
        , navKey = navKey
        , url = url
        , phaseData = CreateJoinPhase { sessionCode = "", options = defaultOptions }
        }



-- UPDATE


{-| Handle incoming messages.
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Global message types
        ChannelIsUp up ->
            if up then
                case Parser.parse urlParser model.url of
                    Just globalData ->
                        joinGame model globalData

                    Nothing ->
                        pure model

            else
                -- meh
                pure model

        UrlChanged url ->
            -- Handle a URL change, e.g. from Nav.pushUrl or back/forward browser buttons.
            pure { model | url = url }

        LinkClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.navKey (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        Error error ->
            pure { model | lastError = Just error }

        -- User creates/joins a game
        JoinGame code ->
            case model.phaseData of
                CreateJoinPhase _ ->
                    joinGame model { sessionCode = code, options = defaultOptions }

                _ ->
                    update (Error "Got join request in wrong phase") model

        JoinGameResult result ->
            case result of
                Success code ->
                    let
                        newGlobalData old =
                            { sessionCode = code, options = old.options }

                        newPhaseData =
                            case model.phaseData of
                                WaitingPhase waitingData ->
                                    WaitingPhase
                                        { message = waitingData.message ++ " (session code: " ++ code ++ ")"
                                        , globalData = newGlobalData waitingData.globalData
                                        }

                                _ ->
                                    model.phaseData
                    in
                    pure { model | phaseData = newPhaseData }

                Failure error ->
                    update (Error error) model

                _ ->
                    pure model

        -- Notification of game being ready
        GameReady result ->
            case result of
                Success globalData ->
                    pure { model | phaseData = EntryPhase (EntryPage.State.initState globalData) }

                Failure error ->
                    update (Error error) model

                _ ->
                    pure model

        -- Notification of all dares being collected
        ReceiveDares result ->
            case result of
                Success dares ->
                    case model.phaseData of
                        WaitingPhase phaseData ->
                            pure
                                { model
                                    | phaseData =
                                        ActivePhase
                                            (GameplayPage.State.initState dares phaseData.globalData)
                                }

                        EntryPhase phaseData ->
                            pure
                                { model
                                    | phaseData =
                                        ActivePhase
                                            (GameplayPage.State.initState dares phaseData.globalData)
                                }

                        _ ->
                            update (Error "Received dares in unexpected phase") model

                -- Handle as any other error.
                Failure error ->
                    update (Error error) model

                _ ->
                    pure model

        -- Messages to pass to subpage handling
        EntryPageMsg innerMsg ->
            case model.phaseData of
                EntryPhase data ->
                    case innerMsg of
                        EntryPage.Types.EndSetupPhase ->
                            if List.any String.isEmpty (Array.toList data.inputs) then
                                pure { model | lastError = Just "Enter something in each input box" }

                            else
                                EntryPage.State.update innerMsg data
                                    |> Tuple.mapFirst
                                        (\_ ->
                                            { model
                                                | phaseData =
                                                    WaitingPhase
                                                        { message = "submitting dares"
                                                        , globalData = data.globalData
                                                        }
                                                , lastError = Nothing
                                            }
                                        )
                                    |> Tuple.mapSecond (Cmd.map EntryPageMsg)

                        _ ->
                            EntryPage.State.update innerMsg data
                                |> Tuple.mapFirst (\a -> { model | phaseData = EntryPhase a })
                                |> Tuple.mapSecond (Cmd.map EntryPageMsg)

                _ ->
                    update (Error "Got entry page message in wrong phase") model

        GameplayPageMsg innerMsg ->
            case model.phaseData of
                ActivePhase data ->
                    GameplayPage.State.update innerMsg data
                        |> Tuple.mapFirst (\a -> { model | phaseData = ActivePhase a })
                        |> Tuple.mapSecond (Cmd.map GameplayPageMsg)

                _ ->
                    update (Error "Got entry page message in wrong phase") model


joinGame : Model -> GlobalData -> ( Model, Cmd Msg )
joinGame model globalData =
    Channel.sendRpc
        { model
            | phaseData =
                WaitingPhase
                    { message = "players joining"
                    , globalData = globalData
                    }
        }
        (Request.new "join_game"
            |> Request.addString "code" globalData.sessionCode
            |> Request.addInt "rounds" globalData.options.rounds
            |> Request.addInt "skips" globalData.options.skips
        )
