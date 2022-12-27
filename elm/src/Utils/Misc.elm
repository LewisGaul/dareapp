module Utils.Misc exposing (toAlphaNum)


toAlphaNum : String -> String
toAlphaNum string =
    let
        convChar char =
            if Char.isAlphaNum char then
                char

            else
                '-'
    in
    List.map convChar (String.toList string) |> String.fromList
