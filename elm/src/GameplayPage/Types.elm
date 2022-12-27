module GameplayPage.Types exposing (Model, Msg(..), Transition(..))

import EnTrance.Channel exposing (SendPort)
import EnTrance.Types exposing (RpcData)



-- MODEL


type alias Model =
    { sendPort : SendPort Msg
    , playerId : Int
    , currentDare : Maybe String
    , round : Int
    , remainingSkips : Int
    , transition : Transition
    }


type Transition
    = Ready
    | Decision
    | Waiting
    | Outcome String
    | Finished



-- MESSAGES


type Msg
    = Error String
    | MakeDecision Bool
    | ReceivedOutcome (RpcData String)
    | NextRound
