module Main exposing (main)

import Browser
import Comms exposing (subscriptions)
import State exposing (init, update)
import Types exposing (Model, Msg(..))
import View exposing (view)



-- MAIN


main : Program { basePath : String } Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }
