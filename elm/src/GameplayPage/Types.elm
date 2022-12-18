module GameplayPage.Types exposing (Model, Msg(..), Transition(..))

import EnTrance.Channel exposing (SendPort)



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
    | Accepted
    | Refused
    | Finished



-- MESSAGES


type Msg
    = NextRound Bool
