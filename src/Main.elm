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
init { windowWidth, windowHeight, names, focusPoints } =
    let
        positions =
            focusPoints
                |> List.map (\focus -> ( focus.name, focus.position ))
                |> Dict.fromList

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
    , focusPoints : List FocusPoint
    }


type alias FocusPoint =
    { name : String
    , position : Point
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
