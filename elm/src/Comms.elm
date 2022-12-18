port module Comms exposing (appSend, subscriptions)

import EnTrance.Channel as Channel
import EnTrance.Feature.Gen as Gen
import Json.Decode as Decode exposing (Decoder)
import Types exposing (Msg(..))



{- PORTS

   - `appSend` - send message to the server
   - `appRecv` - receive a notification from the server
   - `appIsUp` - get notifications of up/down status
   - `errorRecv` - get any global errors
-}


port appSend : Channel.SendPort msg


port appRecv : Channel.RecvPort msg


port appIsUp : Channel.IsUpPort msg


port errorRecv : Channel.ErrorRecvPort msg


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ errorRecv Error
        , appIsUp ChannelIsUp
        , Channel.sub appRecv Error notifications
        ]


{-| The notifications we want to decode.
-}
notifications : List (Decoder Msg)
notifications =
    [ decodeReceivedDares
    ]


decodeReceivedDares : Decoder Msg
decodeReceivedDares =
    Gen.decodeRpc "receive_dares" (Decode.list Decode.string)
        |> Decode.map ReceiveDares
