module State exposing (init, update)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Comms
import EntryPage.State
import EntryPage.Types exposing (Msg(..))
import GameplayPage.State
import RemoteData exposing (RemoteData(..))
import Response exposing (pure)
import Types exposing (Model, Msg(..), Options, Phase(..))
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
        , phaseData = CreateJoinPhase { code = "" }
        }



-- UPDATE


{-| Handle incoming messages.
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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

        JoinGame code ->
            let
                globalData =
                    { sessionCode = code, options = testingOptions }
            in
            pure { model | phaseData = EntryPhase (EntryPage.State.initState globalData) }

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

        EntryPageMsg innerMsg ->
            case model.phaseData of
                EntryPhase data ->
                    case innerMsg of
                        EndSetupPhase ->
                            EntryPage.State.update innerMsg data
                                |> Tuple.mapFirst
                                    (\a ->
                                        { model
                                            | phaseData =
                                                WaitingPhase
                                                    { message = "submitting dares"
                                                    , globalData = data.globalData
                                                    }
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

        Error error ->
            pure { model | lastError = Just error }
