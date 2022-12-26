module EntryPage.State exposing (init, update)

import Array
import EnTrance.Channel as Channel
import EnTrance.Request as Request
import EntryPage.Comms as Comms
import EntryPage.Types exposing (Model, Msg(..))
import RemoteData exposing (RemoteData(..))
import Response exposing (pure)
import SharedTypes exposing (GlobalData, Options, dummyGlobalData)



-- INITIAL STATE


init : () -> Model
init _ =
    { sendPort = Comms.entryPageSend
    , globalData = dummyGlobalData
    , inputs = Array.initialize dummyGlobalData.options.rounds (always "")
    }



-- UPDATE


{-| Handle incoming messages.
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DareEntry idx text ->
            pure { model | inputs = Array.set idx text model.inputs }

        EndSetupPhase ->
            if List.any String.isEmpty (Array.toList model.inputs) then
                -- TODO: handle error
                pure model
                --update
                --    (Error "Enter something in each input box")
                --    model

            else
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
