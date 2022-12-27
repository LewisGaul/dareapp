module JoinPage.Types exposing (Model, Msg(..))

import EnTrance.Channel as Channel


type alias Model =
    { sendPort : Channel.SendPort Msg
    , sessionCode : String
    }


type Msg
    = Error String
