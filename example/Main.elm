module Main exposing (main)

import FFI exposing (..)
import Json.Decode as D exposing (Decoder, Value)
import Json.Encode as E
import Task exposing (Task)


main =
    run
        [ fetchJson { url = "../elm.json" }
            |> Task.andThen log
        ]


fetchJson =
    function
        [ ( "url", .url >> E.string )
        ]
        """
        let res = await fetch(url)
        if (!res.ok) throw res.statusText
        return await res.json()
        """


log =
    function [ ( "val", identity ) ]
        "console.log(val)"



-- HELPERS


run : List (Task a b) -> TaskProgram
run tasks =
    Platform.worker
        { init =
            always
                ( ()
                , Task.attempt
                    (always (Ok ()))
                    (Task.sequence tasks)
                )
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = always Sub.none
        }


type alias TaskProgram =
    Program () () (Result () ())
