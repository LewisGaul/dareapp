module EntryPage.State exposing (initState, update)

import Array
import EnTrance.Channel as Channel
import EnTrance.Request as Request
import EntryPage.Comms as Comms
import EntryPage.Types exposing (Model, Msg(..))
import RemoteData exposing (RemoteData(..))
import Response exposing (pure)
import Utils.Inject as Inject
import Utils.Types exposing (Options)



-- INITIAL STATE


initState : Options -> Model
initState options =
    { sendPort = Comms.entryPageSend
    , inputs = Array.initialize options.rounds (always "")
    , waitingState = False
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Error error ->
            Inject.send (Inject.Error "entry page" error) model

        DareEntry idx text ->
            pure { model | inputs = Array.set idx text model.inputs }

        SubmitDares ->
            if List.any String.isEmpty (Array.toList model.inputs) then
                update (Error "Enter something in each input box") model

            else
                Channel.sendRpc
                    model
                    (Request.new "submit_dares"
                        |> Request.addStrings "dares" (Array.toList model.inputs)
                    )

        SubmitDaresResult result ->
            case result of
                Success () ->
                    pure { model | waitingState = True }

                Failure error ->
                    update (Error error) model

                _ ->
                    pure model
