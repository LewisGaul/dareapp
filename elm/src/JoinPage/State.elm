module JoinPage.State exposing (initState, update)

import JoinPage.Comms exposing (joinPageSend)
import JoinPage.Types exposing (Model, Msg(..))
import Response exposing (pure)
import Utils.Inject as Inject


initState : Model
initState =
    { sendPort = joinPageSend
    , sessionCode = ""
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Error error ->
            Inject.send (Inject.Error "join page" error) model
