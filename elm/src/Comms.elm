port module Comms exposing (sendPort, subscriptions)

import EnTrance.Channel as Channel
import Json.Decode exposing (Decoder)
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


sendPort : Channel.SendPort msg
sendPort =
    appSend


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
    [
    ]
