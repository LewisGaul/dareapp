module EntryPage.State exposing (initState, update)

import Array
import EnTrance.Channel as Channel
import EnTrance.Request as Request
import EntryPage.Comms as Comms
import EntryPage.Types exposing (Model, Msg(..))
import RemoteData exposing (RemoteData(..))
import Response exposing (pure)
import Types exposing (GlobalData, Options)



-- INITIAL STATE


initState : GlobalData -> Model GlobalData
initState globalData =
    { sendPort = Comms.entryPageSend
    , globalData = globalData
    , inputs = Array.initialize globalData.options.rounds (always "")
    }



-- UPDATE


{-| Handle incoming messages.
-}
update : Msg -> Model GlobalData -> ( Model GlobalData, Cmd Msg )
update msg model =
    case msg of
        DareEntry idx text ->
            pure { model | inputs = Array.set idx text model.inputs }

        EndSetupPhase ->
            Channel.sendRpc
                model
                (Request.new "submit_dares"
                    |> Request.addString "code" model.globalData.sessionCode
                    |> Request.addStrings "dares" (Array.toList model.inputs)
                )

        SubmitDaresResult result ->
            case result of
                Failure error ->
                    -- TODO: handle error
                    --update (Error error) model
                    pure model

                _ ->
                    pure model

        Error error ->
            -- TODO
            pure model
