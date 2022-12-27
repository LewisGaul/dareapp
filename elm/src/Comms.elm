port module Comms exposing (appSend, subscriptions)

import EnTrance.Channel as Channel
import EntryPage.Comms as EntryPage
import GameplayPage.Comms as GameplayPage
import JoinPage.Comms as JoinPage
import Types exposing (GlobalData, Msg(..))



{- PORTS

   - `appSend` - send message to the server
   - `appRecv` - receive a notification from the server
   - `appIsUp` - get notifications of up/down status
   - `errorRecv` - get any global errors
-}


port appSend : Channel.SendPort msg


port appIsUp : Channel.IsUpPort msg


port errorRecv : Channel.ErrorRecvPort msg


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ appIsUp ChannelIsUp
        , errorRecv Error
        , Sub.map JoinPageMsg JoinPage.subscriptions
        , Sub.map EntryPageMsg EntryPage.subscriptions
        , Sub.map GameplayPageMsg GameplayPage.subscriptions
        ]
