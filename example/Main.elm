module Main exposing (main)

import FFI
import Json.Encode exposing (Value)
import Task exposing (Task)


main =
    Task.sequence
        [ fetchJson "/elm.json"
            |> Task.andThen log
        , windowWidth
            |> Task.andThen log

        --, noAccessToElmFunctions
        --, noImports
        --, syntaxErrorAreErrorsToo
        ]
        |> run


fetchJson : String -> Task Value Value
fetchJson url =
    FFI.function
        [ ( "_url_", Json.Encode.string url )
        ]
        """
    return fetch(_url_).then((res)=> {
        if (!res.ok) throw res.statusText
        return res.json()
    })
    """


log val =
    FFI.function
        [ ( "val", val )
        ]
        """
    console.log(val)
    """


windowWidth =
    FFI.function
        []
        """
    return window.innerWidth
        //>> in a window: Ok 1440
        //>> headless: Err { "name": "ReferenceError", "message": "window is not defined" }
    """


noAccessToElmFunctions =
    FFI.function
        []
        """
    console.log(fetch)
        //logs: Function
    console.log($elm$core$List$cons)
        //>> Err { "name": "ReferenceError", "message": "$elm$core$List$cons is not defined" }
    console.log(__Scheduler_binding)
        //>> Err { "name": "ReferenceError", "message": "__Scheduler_binding is not defined" }
    """


noImports =
    FFI.function
        []
        """
    console.log(require('fs/promises').readFile)
        //logs: [AsyncFunction: readFile]
    import { val } from "my-module"
        //>> browser: Err { "name": "Uncaught EvalError", "message": "call to Function() blocked by Content Security Policy" }
        //>> node: Err { "name": "SyntaxError", "message": "Cannot use import statement outside a module" }
    """


syntaxErrorAreErrorsToo =
    FFI.function
        []
        """
    return "forgot quote?
        //>> Err { "name": "SyntaxError", "message": \"\"\" string literal contains an unescaped line break" }
    """



-- HELPERS


run : Task a b -> TaskProgram
run task =
    Platform.worker
        { init =
            always
                ( ()
                , Task.attempt (always (Ok ())) task
                )
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = always Sub.none
        }


type alias TaskProgram =
    Program () () (Result () ())
