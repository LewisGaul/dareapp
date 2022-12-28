port module GameplayPage.Comms exposing
    ( decodeModel
    , gameplayPageRecv
    , gameplayPageSend
    , subscriptions
    )

import EnTrance.Channel as Channel
import GameplayPage.Types exposing (DareState, Model, Msg(..), Transition(..))
import Json.Decode as Decode exposing (Decoder)
import Utils.Misc exposing (decodeOptions, decodeRequest)
import Utils.Types exposing (Options)



-- Ports


port gameplayPageSend : Channel.SendPort msg


port gameplayPageRecv : Channel.RecvPort msg


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ Channel.sub gameplayPageRecv Error decoders
        ]


{-| Decoders for all the notifications we can receive
-}
decoders : List (Decoder Msg)
decoders =
    [ decodeRequest "next_dare" decodeDareState NextRoundResult
    , decodeRequest "outcome" Decode.string ReceivedOutcome
    ]


decodeDareState : Decoder DareState
decodeDareState =
    Decode.map2 DareState
        (Decode.field "round" Decode.int)
        (Decode.field "dare" Decode.string)


decodeTransition : Decoder Transition
decodeTransition =
    let
        constructTransition : Int -> Maybe String -> Maybe String -> Maybe String -> Transition
        constructTransition round dare choice outcome =
            if round == 0 then
                Ready

            else
                case ( dare, choice, outcome ) of
                    ( Nothing, Nothing, Nothing ) ->
                        AwaitingNextRound round

                    ( Just d, Nothing, Nothing ) ->
                        Decision { round = round, dare = d }

                    ( Just d, Just "accept", Nothing ) ->
                        AwaitingDecision { round = round, dare = d } True

                    ( Just d, Just "refuse", Nothing ) ->
                        AwaitingDecision { round = round, dare = d } False

                    ( Just d, _, Just message ) ->
                        Outcome { round = round, dare = d } message

                    _ ->
                        -- TODO: Erk! Hope this never happens...
                        Ready
    in
    Decode.map4 constructTransition
        (Decode.field "current_round" Decode.int)
        (Decode.field "current_dare" (Decode.nullable Decode.string))
        (Decode.field "dare_choice" (Decode.nullable Decode.string))
        (Decode.field "outcome" (Decode.nullable Decode.string))


decodeModel : Decoder Model
decodeModel =
    let
        constructModel : Options -> Int -> Transition -> Model
        constructModel options remainingSkips transition =
            { sendPort = gameplayPageSend
            , options = options
            , remainingSkips = remainingSkips
            , transition = transition
            }
    in
    Decode.map3 constructModel
        decodeOptions
        (Decode.field "remaining_skips" Decode.int)
        decodeTransition
