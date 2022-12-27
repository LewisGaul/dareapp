module EntryPage.State exposing (initState, update)

import Array
import EnTrance.Channel as Channel
import EnTrance.Request as Request
import EntryPage.Comms as Comms
import EntryPage.Types exposing (Model, Msg(..))
import RemoteData exposing (RemoteData(..))
import Response exposing (pure)
import Types exposing (GlobalData)
import Utils.Inject as Inject



-- INITIAL STATE


initState : GlobalData -> Model
initState globalData =
    { sendPort = Comms.entryPageSend
    , inputs = Array.initialize globalData.options.rounds (always "")
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Error error ->
            Inject.send (Inject.Error "entry page" error) model

        DareEntry int string ->
            pure model

        EndSetupPhase ->
            pure model

        SubmitDaresResult result ->
            pure model



--updateXXX : Msg -> Model -> ( Model, Cmd Msg )
--updateXXX msg model =
--    case msg of
--        DareEntry idx text ->
--            pure { model | inputs = Array.set idx text model.inputs }
--
--        EndSetupPhase ->
--            Channel.sendRpc
--                model
--                (Request.new "submit_dares"
--                    |> Request.addString "code" model.globalData.sessionCode
--                    |> Request.addStrings "dares" (Array.toList model.inputs)
--                )
--
--        SubmitDaresResult result ->
--            case result of
--                Failure error ->
--                    -- TODO: handle error
--                    --update (Error error) model
--                    pure model
--
--                _ ->
--                    pure model
--
--        Error error ->
--            -- TODO
--            pure model
