port module GameplayPage.Comms exposing
    ( gameplayPageRecv
    , gameplayPageSend
    , notifications
    )

import EnTrance.Channel as Channel
import GameplayPage.Types exposing (Msg(..))
import Json.Decode exposing (Decoder)



-- Ports


port gameplayPageSend : Channel.SendPort msg


port gameplayPageRecv : Channel.RecvPort msg


{-| The notifications we want to decode.
-}
notifications : List (Decoder Msg)
notifications =
    []
