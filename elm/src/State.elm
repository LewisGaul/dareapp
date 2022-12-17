module State exposing (init, update)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Comms
import RemoteData exposing (RemoteData(..))
import Response exposing (pure)
import Types exposing (Model, Msg(..))
import Url
import Url.Parser exposing ((<?>))



-- INITIAL STATE


init : { basePath : String } -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init { basePath } url navKey =
    pure
        { sendPort = Comms.sendPort
        , lastError = Nothing
        , basePath = basePath
        , navKey = navKey
        , url = url
        }



-- UPDATE


{-| Handle incoming messages.
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChannelIsUp up ->
            if up then
                -- TODO: Do something?
                pure model

            else
                -- meh
                pure model

        GotSomething result ->
            case result of
                Success _ ->
                    pure model

                -- Handle as any other error.
                Failure error ->
                    update (Error error) model

                _ ->
                    pure model

        UrlChanged url ->
            -- Handle a URL change, e.g. from Nav.pushUrl or back/forward browser buttons.
            pure { model | url = url }

        LinkClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.navKey (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        Error error ->
            pure { model | lastError = Just error }
