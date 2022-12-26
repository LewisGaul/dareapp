module Phases exposing (Phase(..), entryPhase, gameplayPhase)

import EntryPage.State
import EntryPage.Types
import EntryPage.View
import GameplayPage.State
import GameplayPage.Types
import GameplayPage.View
import Html exposing (Html)


type alias PhaseFuncs msg model =
    { init : () -> model
    , view : model -> List (Html msg)
    , update : msg -> model -> ( model, Cmd msg )
    }


type Phase
    = EntryPhase (PhaseFuncs EntryPage.Types.Msg EntryPage.Types.Model)
    | GameplayPhase (PhaseFuncs GameplayPage.Types.Msg GameplayPage.Types.Model2)


entryPhase : Phase
entryPhase =
    EntryPhase
        { init = EntryPage.State.init
        , view = EntryPage.View.view
        , update = EntryPage.State.update
        }


gameplayPhase : Phase
gameplayPhase =
    GameplayPhase
        { init = GameplayPage.State.init
        , view = GameplayPage.View.view
        , update = GameplayPage.State.update
        }
