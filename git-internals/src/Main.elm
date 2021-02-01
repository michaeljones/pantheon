module Main exposing (..)

import Array exposing (Array)
import Browser
import Browser.Events
import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Keyboard



---- MODEL ----


type alias Model =
    { layers : Array Slide
    , currentIndex : Int
    , farthestIndex : Int
    , fresh : Bool
    , offset : Point
    , dragState : DragState
    }


type alias Slide =
    { path : String
    , position : Point
    }


type alias Point =
    { x : Float, y : Float }


type DragState
    = Static
    | Moving Point


init : Flags -> ( Model, Cmd Msg )
init { windowWidth, windowHeight, names } =
    let
        positions =
            Dict.fromList
                [ ( "git", { x = 676, y = 286 } )
                , ( "timeline", { x = 2014, y = 594 } )
                , ( "tarballs", { x = 3171, y = 947 } )
                , ( "git-in-git", { x = 2558, y = 1091 } )
                , ( "inconsistency", { x = 1860, y = 1201 } )
                , ( "plumbing", { x = 869, y = 1250 } )
                , ( "data-store", { x = 587, y = 1478 } )
                , ( "sha-1", { x = 677, y = 1808 } )
                , ( "content-addressable", { x = 754, y = 2045 } )
                , ( "git-objects", { x = 769, y = 2316 } )
                , ( "git-objects-breakdown", { x = 816, y = 2539 } )
                , ( "directory-structure", { x = 1474, y = 2568 } )
                , ( "first-commit-file-1", { x = 1926, y = 2725 } )
                , ( "first-commit-file-2", { x = 2038, y = 2779 } )
                , ( "first-commit-dir", { x = 2320, y = 2697 } )
                , ( "first-commit-file-3", { x = 2319, y = 2483 } )
                , ( "first-commit-root", { x = 2370, y = 2378 } )
                , ( "first-commit-commit", { x = 2529, y = 2254 } )
                , ( "first-commit-branch", { x = 2782, y = 2077 } )
                , ( "second-commit-file-1", { x = 2567, y = 2264 } )
                , ( "second-commit-dir", { x = 2782, y = 2511 } )
                , ( "second-commit-root", { x = 2769, y = 2347 } )
                , ( "second-commit-commit", { x = 2684, y = 2178 } )
                , ( "more-commits", { x = 3253, y = 2140 } )
                , ( "branch-commits", { x = 3779, y = 2136 } )
                , ( "merge-commits", { x = 4049, y = 2120 } )
                , ( "final-branching", { x = 4701, y = 2230 } )
                , ( "integrity", { x = 5316, y = 1972 } )
                , ( "tags", { x = 5265, y = 2138 } )
                , ( "branch-work", { x = 5039, y = 2399 } )
                , ( "branch-rework", { x = 5096, y = 2495 } )
                , ( "history-of-history", { x = 4989, y = 2800 } )
                , ( "why-source-control", { x = 4371, y = 2952 } )
                , ( "mistakes", { x = 3903, y = 3130 } )
                , ( "thanks", { x = 3307, y = 3387 } )
                ]

        slides =
            names

        screenX =
            toFloat windowWidth / 2.0

        screenY =
            toFloat windowHeight / 2.0

        offset { x, y } =
            { x = screenX - x, y = screenY - y }

        layers =
            slides
                |> List.filterMap
                    (\name ->
                        Dict.get name positions
                            |> Maybe.map (\pos -> { path = "/layers/" ++ name ++ ".svg", position = offset pos })
                    )
                |> Array.fromList
    in
    ( { layers = layers
      , currentIndex = 0
      , farthestIndex = 0
      , fresh = False
      , offset = { x = 0, y = 0 }
      , dragState = Static
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = KeyboardMsg Keyboard.Msg
    | DragStart Point
    | DragMove Point
    | DragStop


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        KeyboardMsg keyboardMsg ->
            let
                keys =
                    Keyboard.update keyboardMsg []
            in
            if List.member Keyboard.ArrowLeft keys || List.member (Keyboard.Character "S") keys then
                let
                    numLayers =
                        Array.length model.layers

                    newIndex =
                        clamp 0 numLayers (model.currentIndex - 1)

                    newOffset =
                        Array.get newIndex model.layers
                            |> Maybe.map (\layer -> { x = layer.position.x, y = layer.position.y })
                            |> Maybe.withDefault model.offset
                in
                ( { model
                    | currentIndex = newIndex
                    , offset = newOffset
                    , fresh = False
                  }
                , Cmd.none
                )

            else if List.member Keyboard.ArrowRight keys || List.member (Keyboard.Character "F") keys then
                let
                    numLayers =
                        Array.length model.layers

                    newIndex =
                        clamp 0 numLayers (model.currentIndex + 1)

                    newOffset =
                        Array.get newIndex model.layers
                            |> Maybe.map (\layer -> { x = layer.position.x, y = layer.position.y })
                            |> Maybe.withDefault model.offset
                in
                ( { model
                    | currentIndex = newIndex
                    , farthestIndex = Basics.max newIndex model.farthestIndex
                    , fresh = newIndex > model.farthestIndex
                    , offset = newOffset
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        DragStart start ->
            ( { model | dragState = Moving start }, Cmd.none )

        DragMove { x, y } ->
            case model.dragState of
                Moving last ->
                    let
                        diff =
                            { x = x - last.x
                            , y = y - last.y
                            }
                    in
                    ( { model
                        | offset = { x = diff.x + model.offset.x, y = diff.y + model.offset.y }
                        , dragState = Moving { x = x, y = y }
                      }
                    , Cmd.none
                    )

                Static ->
                    ( model, Cmd.none )

        DragStop ->
            ( { model | dragState = Static }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    let
        { x, y } =
            model.offset

        offsetX =
            style "left" (String.fromFloat x ++ "px")

        offsetY =
            style "top" (String.fromFloat y ++ "px")

        layers =
            Array.toList model.layers
                |> List.take (model.farthestIndex + 1)
                |> List.indexedMap
                    (\index { path } ->
                        if index == model.currentIndex then
                            if model.fresh then
                                img [ class "layer-image layer-current", src path ] []

                            else
                                img [ class "layer-image layer-past", src path ] []

                        else
                            img [ class "layer-image layer-past", src path ] []
                    )

        transitionOverride =
            case model.dragState of
                Moving _ ->
                    [ style "transition-duration" "0s" ]

                Static ->
                    []
    in
    div [ class "layer-holder" ]
        [ div (List.append [ class "layer-group", offsetX, offsetY ] transitionOverride)
            layers
        ]



---- PROGRAM ----


type alias Flags =
    { windowWidth : Int
    , windowHeight : Int
    , names : List String
    }


main : Program Flags Model Msg
main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }


subscriptions model =
    let
        dragSub =
            case model.dragState of
                Static ->
                    Sub.none

                Moving _ ->
                    Sub.batch
                        [ Browser.Events.onMouseMove (positionDecoder DragMove)
                        , Browser.Events.onMouseUp (Decode.succeed DragStop)
                        ]
    in
    Sub.batch
        [ dragSub
        , Browser.Events.onMouseDown (positionDecoder DragStart)
        , Keyboard.subscriptions |> Sub.map KeyboardMsg
        ]


positionDecoder msg =
    Decode.map2 Point
        (Decode.field "pageX" Decode.float)
        (Decode.field "pageY" Decode.float)
        |> Decode.map msg
