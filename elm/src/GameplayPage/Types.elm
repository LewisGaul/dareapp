module GameplayPage.Types exposing (Model2, Msg(..), Transition(..))

import EnTrance.Channel exposing (SendPort)
import EnTrance.Types exposing (RpcData)
import SharedTypes exposing (GlobalData)



-- MODEL


type alias Model globalData =
    { sendPort : SendPort Msg
    , globalData : globalData
    , dares : List String
    , round : Int
    , remainingSkips : Int
    , transition : Transition
    }


type alias Model2 =
    { sendPort : SendPort Msg
    , globalData : GlobalData
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
