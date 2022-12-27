module JoinPage.State exposing (initState, update)

import EnTrance.Channel as Channel
import EnTrance.Request as Request
import JoinPage.Comms exposing (joinPageSend)
import JoinPage.Types exposing (Model, Msg(..))
import RemoteData exposing (RemoteData(..))
import Response exposing (pure)
import Utils.Inject as Inject
import Utils.Types exposing (Options)


initState : Model
initState =
    { sendPort = joinPageSend
    , waitingState = Nothing
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Error error ->
            Inject.send (Inject.Error "join page" error) model

        Join code options ->
            joinGame model code options

        JoinResult result ->
            case result of
                Failure error ->
                    update (Error error) model

                Success code ->
                    Inject.send (Inject.SetUrlCode code)
                        { model | waitingState = Just { code = code } }

                _ ->
                    pure model


joinGame : Model -> String -> Maybe Options -> ( Model, Cmd Msg )
joinGame model code options =
    let
        baseRequest =
            Request.new "join_game"
                |> Request.addString "code" code

        request =
            case options of
                Just opts ->
                    baseRequest
                        |> Request.addInt "rounds" opts.rounds
                        |> Request.addInt "skips" opts.skips

                Nothing ->
                    baseRequest
    in
    Channel.sendRpc model request
