# elm-ffi

- __THIS USES HACKS__: I decline all responsabilities.
- Calling JS from Elm is a bit of a controversy. This is not recognized as a standard practice among the Elm community.  Favourise using ports and WebComponents, if you use a lot of JS in Elm maybe what you need is JS?
- You can find a previous version of this using Elm's Kernel in the `Kernel` branch of this repo, this version is a complete rip-off from [joakin](https://github.com/joakin/elm-js-interop/)
- Do not forget: JS code within Elm is not touched by JS compilers/build tools.

This should work where modern javascript works: browsers, node, deno, bun...

## Setup

Install both Elm & JS dependencies:

    elm install Warry/elm-ffi
    npm install Warry/elm-ffi --save

Apply the polyfill before initialiazing your Elm app:

    import 'elm-ffi' // just import it, and that's it.
    import { Elm } from './Main.elm'
    let app = Elm.Main.init(<your code>)

## Usage

**Read global values from javascript**

```elm
read : JsCode -> Value
```

**Create and call asynchronous javascript functions from Elm**

```elm
function : List ( String, params -> Value ) -> JsCode -> params -> Task Error Value
```

## Examples

```elm
import FFI
import Json.Encode exposing (Value)
import Json.Decode exposing (Decoder)
import Task

{-
when FFI.read fails, value is undefined (not readable by elm/json)
-}
language : String
language =
    FFI.read "return window.navigator.language"
    |> Decode.decodeValue Decode.string
    |> Result.withDefault "en"

{-
it's good practice to declare functions using only the first two parameters,
leaving the given function parameter to currying.
this way function code is cached properly, and execution will be fast.
-}
fetchJson : { url: String } -> Task Error Value
fetchJson =
    FFI.function
        [ ( "url", .url >> Json.Encode.string )
        ]
        """
        let res = await fetch(url)
        if (!res.ok) throw res.statusText
        return await res.json()
        """

fetchUser : Cmd (Result String User)
fetchUser =
    fetchJson { url = "/api/user" }
        |> FFI.decode decodeUser
        |> Task.mapError FFI.errorToString
        |> Task.perform identity
```

see example/

## How fast is it?

Faster than `eval()`, the little overhead consists in converting parameters' values to pojo then passing them to the function using _the hack_. If your functions are declared at the top level then they are _pre-compiled_ on load.

## How safe is it?

- JS code is guaranteed to run within a Task meaning that your Elm runtime still can't break.
  - Effects are still managed, creating a JS function in Elm won't do anything until the `Cmd` is ran.
- JS code runs in isolation, meaning that you can only access function arguments and global references.
