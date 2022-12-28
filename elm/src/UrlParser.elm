module UrlParser exposing (UrlResult(..), parseUrl)

import Url
import Url.Parser as Parser exposing ((<?>))
import Url.Parser.Query as Query
import Utils.Types exposing (Options, PlayerID, SessionCode)


type UrlResult
    = PlainUrl
    | InactiveSessionUrl SessionCode (Maybe Options)
    | ActiveSessionUrl SessionCode Int
    | InvalidUrl String


parseUrl : Url.Url -> UrlResult
parseUrl url =
    Parser.parse urlParser url
        |> Maybe.withDefault (InvalidUrl <| "unexpected path " ++ url.path)


urlParser : Parser.Parser (UrlResult -> a) a
urlParser =
    let
        mapSessionUrlArgs : SessionCode -> Maybe Int -> Maybe Int -> Maybe PlayerID -> UrlResult
        mapSessionUrlArgs code rounds skips playerId =
            case ( rounds, skips, playerId ) of
                ( Nothing, Nothing, Nothing ) ->
                    InactiveSessionUrl code Nothing

                ( Just r, Just s, Nothing ) ->
                    InactiveSessionUrl code (Just { rounds = r, skips = s, players = 2 })

                ( Just r, Nothing, Nothing ) ->
                    InactiveSessionUrl code (Just { rounds = r, skips = (r + 1) // 2 - 1, players = 2 })

                ( Nothing, Just s, Nothing ) ->
                    InactiveSessionUrl code (Just { rounds = 8, skips = s, players = 2 })

                ( Nothing, Nothing, Just player ) ->
                    ActiveSessionUrl code player

                ( _, _, Just _ ) ->
                    InvalidUrl "if rejoining an existing game then 'rounds' and 'skips' must not be given"
    in
    Parser.oneOf
        [ Parser.top |> Parser.map PlainUrl
        , Parser.string
            <?> Query.int "rounds"
            <?> Query.int "skips"
            <?> Query.int "p"
            |> Parser.map mapSessionUrlArgs
        ]
