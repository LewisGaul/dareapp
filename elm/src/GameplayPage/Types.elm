module GameplayPage.Types exposing (DareState, Model, Msg(..), Transition(..), roundFromTransition)

import EnTrance.Channel exposing (SendPort)
import EnTrance.Types exposing (RpcData)
import Utils.Types exposing (Options)



-- MODEL


type alias Model =
    { sendPort : SendPort Msg
    , options : Options
    , remainingSkips : Int
    , transition : Transition
    }


type alias DareState =
    { round : Int
    , dare : String
    }


type Transition
    = Ready
    | AwaitingNextRound Int
    | Decision DareState
    | AwaitingDecision DareState Bool
    | Outcome DareState String
    | Finished


roundFromTransition : Transition -> Int -> Int
roundFromTransition transition total =
    case transition of
        Ready ->
            0

        AwaitingNextRound r ->
            r

        Decision dareState ->
            dareState.round

        AwaitingDecision dareState _ ->
            dareState.round

        Outcome dareState _ ->
            dareState.round

        Finished ->
            total



-- MESSAGES


type Msg
    = Error String
    | MakeDecision Bool
    | ReceivedOutcome (RpcData String)
    | NextRound
    | NextRoundResult (RpcData DareState)
