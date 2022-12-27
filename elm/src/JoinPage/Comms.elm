port module JoinPage.Comms exposing
    ( joinPageRecv
    , joinPageSend
    , subscriptions
    )

import EnTrance.Channel as Channel
import JoinPage.Types exposing (Model, Msg(..))
import Json.Decode exposing (Decoder)


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
    []
