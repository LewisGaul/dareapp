port module JoinPage.Comms exposing
    ( joinPageRecv
    , joinPageSend
    , subscriptions
    )

import EnTrance.Channel as Channel
import EnTrance.Feature.Gen as Gen
import EnTrance.Types exposing (RpcData)
import JoinPage.Types exposing (Model, Msg(..))
import Json.Decode as Decode exposing (Decoder)
import Utils.Misc exposing (decodeRequest)
import Utils.Types exposing (Options)


port joinPageSend : Channel.SendPort msg


port joinPageRecv : Channel.RecvPort msg


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ Channel.sub joinPageRecv Error decoders
        ]


{-| Decoders for all the notifications we can receive
-}
decoders : List (Decoder Msg)
decoders =
    [ decodeRequest "join_game" Decode.string JoinResult
    ]
