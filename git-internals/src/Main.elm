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
                [ ( "git", { x = 400, y = 250 } ) -- Manual
                , ( "timeline", { x = 1652, y = 495 } )
                , ( "tarballs", { x = 2579, y = 777 } )
                , ( "git-in-git", { x = 2087, y = 892 } )
                , ( "inconsistency", { x = 1529, y = 980 } )
                , ( "plumbing", { x = 736, y = 1020 } )
                , ( "data-store", { x = 510, y = 1202 } )
                , ( "sha-1", { x = 582, y = 1466 } )
                , ( "content-addressable", { x = 644, y = 1656 } )
                , ( "git-objects", { x = 656, y = 1873 } )
                , ( "git-objects-breakdown", { x = 693, y = 2051 } )
                , ( "directory-structure", { x = 1220, y = 2075 } )
                , ( "first-commit-file-1", { x = 1583, y = 2201 } )
                , ( "first-commit-file-2", { x = 1672, y = 2243 } )
                , ( "first-commit-dir", { x = 1897, y = 2178 } )
                , ( "first-commit-file-3", { x = 1897, y = 2007 } )
                , ( "first-commit-root", { x = 1937, y = 1923 } )
                , ( "first-commit-commit", { x = 2065, y = 1824 } )
                , ( "first-commit-branch", { x = 2267, y = 1682 } )
                , ( "second-commit-file-1", { x = 2095, y = 1831 } )
                , ( "second-commit-dir", { x = 2267, y = 1831 } ) -- Manual
                , ( "second-commit-root", { x = 2257, y = 1831 } ) -- Manual
                , ( "second-commit-commit", { x = 2188, y = 1763 } )
                , ( "more-commits", { x = 2644, y = 1732 } )
                , ( "branch-commits", { x = 3065, y = 1728 } )
                , ( "merge-commits", { x = 3282, y = 1716 } )
                , ( "final-branching", { x = 3803, y = 1804 } )
                , ( "integrity", { x = 4352, y = 1625 } )
                , ( "tags", { x = 4146, y = 1750 } )
                , ( "branch-work", { x = 4074, y = 1939 } )
                , ( "branch-rework", { x = 4120, y = 2016 } )
                , ( "history-of-history", { x = 4034, y = 2260 } ) -- Manual
                , ( "why-source-control", { x = 3459, y = 2388 } ) -- Manual
                , ( "mistakes", { x = 2915, y = 2575 } ) -- Manual
                , ( "git-commit-amend", { x = 2318, y = 2638 } )
                , ( "git-reset", { x = 1749, y = 2837 } )
                , ( "commit-refs", { x = 1070, y = 2934 } )
                , ( "commit-refs", { x = 1070, y = 2934 } )
                , ( "git-rebase", { x = 659, y = 3283 } ) -- Manual
                , ( "git-rebase-i", { x = 943, y = 3516 } ) -- Manual
                , ( "thanks", { x = 1730, y = 3803 } ) -- Manual
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
      , offset = { x = screenX - 400, y = screenY - 250 }
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
