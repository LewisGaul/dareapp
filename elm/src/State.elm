module State exposing (init, update)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Comms
import EntryPage.State as EntryPage
import EntryPage.Types as EntryPhase
import GameplayPage.State as GameplayPage
import GameplayPage.Types as GameplayPhase
import JoinPage.State as JoinPage
import JoinPage.Types as JoinPage
import RemoteData exposing (RemoteData(..))
import Response exposing (pure)
import Toasty
import Types
    exposing
        ( GlobalData
        , Model
        , Msg(..)
        , Phase(..)
        , phaseToString
        )
import Url
import Url.Builder
import Url.Parser
import UrlParser exposing (urlParser)
import Utils.Inject as Inject
import Utils.Toast as Toast



-- INITIAL STATE


{-| There aren't any initial commands, because we defer most initial
processing until we have established a connection with the server.
-}
init : { basePath : String } -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init { basePath } url navKey =
    pure
        { sendPort = Comms.appSend
        , connectionIsUp = False
        , lastError = Nothing
        , toasties = Toasty.initialState

        -- URL handling
        , basePath = basePath
        , navKey = navKey
        , url = url

        -- Phase data
        , phaseData = JoinPhase JoinPage.initState
        }



-- UPDATE


{-| Handle incoming messages.
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Global message types
        ChannelIsUp isUp ->
            let
                updatedModel =
                    { model | connectionIsUp = isUp }
            in
            if isUp then
                case Url.Parser.parse urlParser model.url of
                    Just ( code, options ) ->
                        update
                            (JoinPageMsg <| JoinPage.Join code options)
                            model

                    Nothing ->
                        pure model

            else
                pure updatedModel

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

        Injected (Inject.Toast toast) ->
            update (AddToast toast) model

        Injected (Inject.Error subsys error) ->
            update (Error <| "[" ++ subsys ++ "] " ++ error) model

        Injected (Inject.SetUrlCode code) ->
            ( model
            , Nav.pushUrl model.navKey (Url.Builder.absolute [ code ] [])
            )

        ToastyMsg innerMsg ->
            Toasty.update Toast.config ToastyMsg innerMsg model

        AddToast innerMsg ->
            pure model
                |> Toasty.addToast Toast.config ToastyMsg innerMsg

        -- Messages to pass to subpage handling
        JoinPageMsg innerMsg ->
            case model.phaseData of
                JoinPhase innerModel ->
                    JoinPage.update innerMsg innerModel
                        |> mapJoinPhase model

                _ ->
                    update (msgInUnexpectedPhaseError "join" model.phaseData) model

        EntryPageMsg innerMsg ->
            case model.phaseData of
                EntryPhase innerModel ->
                    EntryPage.update innerMsg innerModel
                        |> mapEntryPhase model

                _ ->
                    update (msgInUnexpectedPhaseError "entry" model.phaseData) model

        GameplayPageMsg innerMsg ->
            case model.phaseData of
                GameplayPhase innerModel ->
                    GameplayPage.update innerMsg innerModel
                        |> mapGameplayPhase model

                _ ->
                    update (msgInUnexpectedPhaseError "gameplay" model.phaseData) model

        -- Messages changing the phase
        StartEntryPhaseNotification result ->
            case result of
                Failure error ->
                    update (Error error) model

                Success ( code, playerId, options ) ->
                    let
                        newPhase =
                            EntryPhase (EntryPage.initState options)
                    in
                    ( { model | phaseData = newPhase }
                    , Nav.pushUrl
                        model.navKey
                        (Url.Builder.absolute
                            [ code ]
                            [ Url.Builder.int "p" playerId ]
                        )
                    )

                _ ->
                    pure model

        StartGameplayPhaseNotification result ->
            case result of
                Failure error ->
                    update (Error error) model

                Success options ->
                    let
                        newPhase =
                            GameplayPhase (GameplayPage.initState options)
                    in
                    pure { model | phaseData = newPhase }

                _ ->
                    pure model


mapJoinPhase : Model -> ( JoinPage.Model, Cmd JoinPage.Msg ) -> ( Model, Cmd Msg )
mapJoinPhase model =
    Response.mapBoth (\x -> { model | phaseData = JoinPhase x }) JoinPageMsg


mapEntryPhase : Model -> ( EntryPhase.Model, Cmd EntryPhase.Msg ) -> ( Model, Cmd Msg )
mapEntryPhase model =
    Response.mapBoth (\x -> { model | phaseData = EntryPhase x }) EntryPageMsg


mapGameplayPhase : Model -> ( GameplayPhase.Model, Cmd GameplayPhase.Msg ) -> ( Model, Cmd Msg )
mapGameplayPhase model =
    Response.mapBoth (\x -> { model | phaseData = GameplayPhase x }) GameplayPageMsg


msgInUnexpectedPhaseError : String -> Phase -> Msg
msgInUnexpectedPhaseError msgPhase currentPhase =
    Error <|
        "Unexpectedly received "
            ++ msgPhase
            ++ " phase message in "
            ++ phaseToString currentPhase
            ++ " phase"
