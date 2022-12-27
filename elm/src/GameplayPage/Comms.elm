port module GameplayPage.Comms exposing
    ( gameplayPageRecv
    , gameplayPageSend
    , subscriptions
    )

import EnTrance.Channel as Channel
import GameplayPage.Types exposing (Msg(..))
import Json.Decode exposing (Decoder)



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
    []
