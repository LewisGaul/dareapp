module Types exposing (Model, Msg(..))

import Browser
import Browser.Navigation as Nav
import EnTrance.Channel exposing (SendPort)
import EnTrance.Types exposing (RpcData)
import Url



-- MODEL


type alias Model =
    { sendPort : SendPort Msg
    , lastError : Maybe String

    -- Data
    -- TODO
    -- Navigation
    , basePath : String
    , navKey : Nav.Key
    , url : Url.Url
    }



-- MESSAGES


type Msg
    = Error String
    | ChannelIsUp Bool
    | GotSomething (RpcData ())
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
