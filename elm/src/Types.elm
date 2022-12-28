module Types exposing
    ( GlobalData
    , Model
    , Msg(..)
    , Phase(..)
    , phaseToString
    )

import Browser
import Browser.Navigation as Nav
import EnTrance.Channel exposing (SendPort)
import EnTrance.Types exposing (RpcData)
import EntryPage.Types as EntryPage
import GameplayPage.Types as GameplayPage
import JoinPage.Types as JoinPage
import Toasty
import Url
import Utils.Inject as Inject
import Utils.Toast exposing (Toast)
import Utils.Types exposing (Options)



-- MODEL


type alias Model =
    { sendPort : SendPort Msg
    , connectionIsUp : Bool
    , lastError : Maybe String
    , toasties : Toasty.Stack Toast

    -- Navigation
    , basePath : String
    , navKey : Nav.Key
    , url : Url.Url

    -- Main state
    , phaseData : Phase
    }


type alias GlobalData =
    { sessionCode : String
    , options : Options
    }


type Phase
    = InitialisingPhase
    | JoinPhase JoinPage.Model
    | EntryPhase EntryPage.Model
    | GameplayPhase GameplayPage.Model


phaseToString : Phase -> String
phaseToString phase =
    case phase of
        InitialisingPhase ->
            "initialising"

        JoinPhase _ ->
            "join"

        EntryPhase _ ->
            "entry"

        GameplayPhase _ ->
            "gameplay"



-- MESSAGES


type Msg
    = -- Global
      ChannelIsUp Bool
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | Error String
    | Injected Inject.Msg
    | ToastyMsg (Toasty.Msg Toast)
    | AddToast Toast
      -- Subpage
    | JoinPageMsg JoinPage.Msg
    | EntryPageMsg EntryPage.Msg
    | GameplayPageMsg GameplayPage.Msg
      -- Change phase
    | StartEntryPhaseNotification (RpcData ( String, Int, Options ))
    | StartGameplayPhaseNotification (RpcData Options)
    | ReconnectionResult (RpcData GameplayPage.Model)
