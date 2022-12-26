module EntryPage.Types exposing (Model, Msg(..))

import Array exposing (Array)
import EnTrance.Channel exposing (SendPort)
import EnTrance.Types exposing (RpcData)
import SharedTypes exposing (GlobalData)



-- MODEL


type alias Model =
    { sendPort : SendPort Msg
    , globalData : GlobalData
    , inputs : Array String
    }



-- MESSAGES


type Msg
    = DareEntry Int String
    | EndSetupPhase
    | SubmitDaresResult (RpcData ())
