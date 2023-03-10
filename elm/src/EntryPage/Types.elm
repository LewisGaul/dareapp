module EntryPage.Types exposing (Model, Msg(..))

import Array exposing (Array)
import EnTrance.Channel exposing (SendPort)
import EnTrance.Types exposing (RpcData)



-- MODEL


type alias Model =
    { sendPort : SendPort Msg
    , inputs : Array String
    , waitingState : Bool
    }



-- MESSAGES


type Msg
    = Error String
    | DareEntry Int String
    | SubmitDares
    | SubmitDaresResult (RpcData ())
