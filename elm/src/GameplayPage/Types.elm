module GameplayPage.Types exposing (Model, Msg(..), Transition(..))

import EnTrance.Channel exposing (SendPort)
import EnTrance.Types exposing (RpcData)



-- MODEL


type alias Model globalData =
    { sendPort : SendPort Msg
    , globalData : globalData
    , dares : List String
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
    = MakeDecision Bool
    | ReceivedOutcome (RpcData String)
    | NextRound
