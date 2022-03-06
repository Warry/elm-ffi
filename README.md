# [RFC] Create [FFI] in Elm

Write JS code as String within Elm, encode arguments to JS values, then apply and get the result within a **`Task`**.

If your foreign function returns a **`Promise`**, it will wait on it before completing the **`Task`**.

## Usage

```elm
FFI.function : List ( String, Value ) -> String -> Task Value Value
```

Takes two arguments:
- the arguments with their associated name
- the body of your function

## Example

```elm
import FFI
import Json.Encode exposing (Value)
import Task

fetchJson : String -> Task Value Value
fetchJson url =
    Promise.function
        [ ( "_url_", Json.Encode.string url )
        ]
        """
        return fetch(_url_).then((res)=> {
            if (!res.ok) throw res.statusText
            return res.json()
        })
        """

```

## How safe is it?

> You can't temper with Elm generated code.

It uses [Function] (rather than `eval()`) meaning that you can only access function arguments and global references; also meaning that there is a small performance penalty.

see example/

[Function]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function
[FFI]: https://en.wikipedia.org/wiki/Foreign_function_interface
