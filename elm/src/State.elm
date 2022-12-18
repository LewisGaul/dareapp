module State exposing (init, update)

import Array
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Comms
import EnTrance.Channel as Channel
import EnTrance.Request as Request
import RemoteData exposing (RemoteData(..))
import Response exposing (pure)
import Types exposing (ActiveModel, Model, Msg(..), Options, Phase(..), SharedData)
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
    let
        initOptions =
            testingOptions
    in
    pure
        { sendPort = Comms.sendPort
        , lastError = Nothing
        , basePath = basePath
        , navKey = navKey
        , url = url
        , code = ""
        , options = initOptions
        , phaseData =
            SetupPhase
                { inputs = Array.initialize initOptions.rounds (always "")
                }
        , sharedData = { allDares = [] }
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

        DareEntry idx text ->
            let
                updatePhaseData old =
                    SetupPhase { old | inputs = Array.set idx text old.inputs }
            in
            case model.phaseData of
                SetupPhase setupData ->
                    pure { model | phaseData = updatePhaseData setupData }

                _ ->
                    update
                        (Error "Unable to handle dare entry outside setup phase")
                        model

        EndSetupPhase ->
            case model.phaseData of
                SetupPhase setupData ->
                    if List.any String.isEmpty (Array.toList setupData.inputs) then
                        update
                            (Error "Enter something in each input box")
                            model

                    else
                        Channel.sendRpc
                            { model | phaseData = WaitingPhase "submitting dares" }
                            (Request.new "submit_dares"
                                |> Request.addString "code" model.code
                                |> Request.addStrings "dares" (Array.toList setupData.inputs)
                            )

                _ ->
                    update
                        (Error "Unable to end setup phase from another phase")
                        model

        SubmitDaresResult result ->
            case result of
                Failure error ->
                    update (Error error) model

                _ ->
                    pure model

        CollectDares result ->
            let
                updateShared : SharedData -> List String -> SharedData
                updateShared old dares =
                    { old | allDares = old.allDares ++ dares }
            in
            case result of
                Success dares ->
                    pure { model | sharedData = updateShared model.sharedData dares }

                -- Handle as any other error.
                Failure error ->
                    update (Error error) model

                _ ->
                    pure model

        NextRound ->
            let
                updatePhaseData : ActiveModel -> Phase
                updatePhaseData old =
                    case old.remainingDares of
                        a :: rest ->
                            ActivePhase
                                { remainingDares = rest
                                , remainingSkips = model.options.skips
                                , currentDare = Just a
                                }

                        [] ->
                            ActivePhase old
            in
            case model.phaseData of
                ActivePhase activeData ->
                    pure { model | phaseData = updatePhaseData activeData }

                _ ->
                    update
                        (Error "Unable to start next round when not in an active game")
                        model

        Error error ->
            pure { model | lastError = Just error }
