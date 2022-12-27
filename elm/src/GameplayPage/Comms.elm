port module GameplayPage.Comms exposing
    ( gameplayPageRecv
    , gameplayPageSend
    , subscriptions
    )

import EnTrance.Channel as Channel
import GameplayPage.Types exposing (DareState, Msg(..))
import Json.Decode as Decode exposing (Decoder)
import Utils.Misc exposing (decodeRequest)



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
    ]


decodeDareState : Decoder DareState
decodeDareState =
    Decode.map2 DareState
        (Decode.field "round" Decode.int)
        (Decode.field "dare" Decode.string)
