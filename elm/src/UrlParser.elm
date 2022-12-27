module UrlParser exposing (urlParser)

import Url.Parser as Parser exposing ((<?>))
import Url.Parser.Query as Query
import Utils.Types exposing (Options)


urlParser : Parser.Parser (( String, Maybe Options ) -> a) a
urlParser =
    Parser.map (\x y z -> ( x, constructOptions y z )) <|
        Parser.string
            <?> Query.int "rounds"
            <?> Query.int "skips"


constructOptions : Maybe Int -> Maybe Int -> Maybe Options
constructOptions rounds skips =
    case ( rounds, skips ) of
        ( Just r, Just s ) ->
            Just { rounds = r, skips = s, players = 2 }

        ( Just r, Nothing ) ->
            Just { rounds = r, skips = r // 2, players = 2 }

        ( Nothing, Just s ) ->
            Just { rounds = 10, skips = s, players = 2 }

        ( Nothing, Nothing ) ->
            Nothing
