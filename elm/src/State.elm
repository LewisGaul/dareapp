module State exposing (init, update)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Comms
import EnTrance.Channel as Channel
import EnTrance.Request as Request
import EntryPage.State
import EntryPage.Types
import GameplayPage.State
import Phases exposing (Phase(..), entryPhase)
import RemoteData exposing (RemoteData(..))
import Response exposing (pure)
import SharedTypes exposing (Options)
import Types exposing (Model, Msg(..))
import Url



-- INITIAL STATE


defaultOptions : Options
defaultOptions =
    { players = 2, rounds = 10, skips = 5 }


testingOptions : Options
testingOptions =
    { players = 2, rounds = 4, skips = 2 }


init : { basePath : String } -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init { basePath } url navKey =
    pure
        { sendPort = Comms.appSend
        , lastError = Nothing
        , basePath = basePath
        , navKey = navKey
        , url = url
        , phase = entryPhase
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
                -- TODO: Do something? Store in state?
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

        --
        ---- User creates/joins a game
        --JoinGame code ->
        --    case model.phaseData of
        --        CreateJoinPhase phaseData ->
        --            Channel.sendRpc
        --                { model
        --                    | phaseData =
        --                        WaitingPhase
        --                            { message = "players joining"
        --                            , globalData =
        --                                { sessionCode = phaseData.code
        --                                , options = defaultOptions
        --                                }
        --                            }
        --                }
        --                (Request.new "join_game"
        --                    |> Request.addString "code" phaseData.code
        --                )
        --
        --        _ ->
        --            update (Error "Got join request in wrong phase") model
        --
        ---- Notification of game being ready
        --GameReady result ->
        --    case result of
        --        Success globalData ->
        --            pure { model | phaseData = EntryPhase (EntryPage.State.initState globalData) }
        --
        --        Failure error ->
        --            update (Error error) model
        --
        --        _ ->
        --            pure model
        --
        ---- Notification of all dares being collected
        --ReceiveDares result ->
        --    case result of
        --        Success dares ->
        --            case model.phaseData of
        --                WaitingPhase phaseData ->
        --                    pure
        --                        { model
        --                            | phaseData =
        --                                ActivePhase
        --                                    (GameplayPage.State.initState dares phaseData.globalData)
        --                        }
        --
        --                EntryPhase phaseData ->
        --                    pure
        --                        { model
        --                            | phaseData =
        --                                ActivePhase
        --                                    (GameplayPage.State.initState dares phaseData.globalData)
        --                        }
        --
        --                _ ->
        --                    update (Error "Received dares in unexpected phase") model
        --
        --        -- Handle as any other error.
        --        Failure error ->
        --            update (Error error) model
        --
        --        _ ->
        --            pure model
        -- Messages to pass to subpage handling
        EntryPageMsg innerMsg ->
            case model.phase of
                EntryPhase data ->
                    case innerMsg of
                        EntryPage.Types.EndSetupPhase ->
                            EntryPage.State.update innerMsg data
                                |> Tuple.mapFirst
                                    (\_ ->
                                        { model
                                            | phase =
                                                WaitingPhase
                                                    { message = "submitting dares"
                                                    , globalData = data.globalData
                                                    }
                                        }
                                    )
                                |> Tuple.mapSecond (Cmd.map EntryPageMsg)

                        _ ->
                            EntryPage.State.update innerMsg data
                                |> Tuple.mapFirst (\a -> { model | phase = EntryPhase a })
                                |> Tuple.mapSecond (Cmd.map EntryPageMsg)

                _ ->
                    update (Error "Got entry page message in wrong phase") model

        GameplayPageMsg innerMsg ->
            case model.phase of
                ActivePhase data ->
                    GameplayPage.State.update innerMsg data
                        |> Tuple.mapFirst (\a -> { model | phase = ActivePhase a })
                        |> Tuple.mapSecond (Cmd.map GameplayPageMsg)

                _ ->
                    update (Error "Got entry page message in wrong phase") model
