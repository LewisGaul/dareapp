module JoinPage.Types exposing (Model, Msg(..), WaitingState)

import EnTrance.Channel as Channel
import EnTrance.Types exposing (RpcData)
import Utils.Types exposing (Options)


type alias Model =
    { sendPort : Channel.SendPort Msg
    , waitingState : Maybe WaitingState
    }


type alias WaitingState =
    { code : String
    }


type Msg
    = Error String
    | Join String (Maybe Options)
    | JoinResult (RpcData String)
