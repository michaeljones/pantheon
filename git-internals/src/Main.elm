module Main exposing (..)

import Browser
import Browser.Events
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Keyboard
import SelectList exposing (SelectList)



---- MODEL ----


type alias Model =
    { layers : SelectList Slide
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


init : ( Model, Cmd Msg )
init =
    ( { layers =
            SelectList.fromLists []
                { path = "/layers/0-git.svg", position = { x = 50, y = 50 } }
                [ { path = "/layers/1-timeline.svg", position = { x = 500, y = 500 } }
                , { path = "/layers/openid.svg", position = { x = 0, y = 500 } }
                ]
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
                    newLayers =
                        SelectList.selectBy -1 model.layers

                    newOffset =
                        Maybe.map SelectList.selected newLayers
                            |> Maybe.map (\layer -> layer.position)
                            |> Maybe.withDefault model.offset
                in
                ( { model
                    | layers = newLayers |> Maybe.withDefault model.layers
                    , offset = newOffset
                  }
                , Cmd.none
                )

            else if List.member Keyboard.ArrowRight keys || List.member (Keyboard.Character "F") keys then
                let
                    newLayers =
                        SelectList.selectBy 1 model.layers

                    newOffset =
                        Maybe.map SelectList.selected newLayers
                            |> Maybe.map (\layer -> layer.position)
                            |> Maybe.withDefault model.offset
                in
                ( { model
                    | layers = newLayers |> Maybe.withDefault model.layers
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
            List.concat
                [ SelectList.listBefore model.layers
                    |> List.map
                        (\{ path } -> img [ class "layer-image layer-past", src path ] [])
                , [ SelectList.selected model.layers ]
                    |> List.map (\{ path } -> img [ class "layer-image layer-current", src path ] [])
                , SelectList.listAfter model.layers
                    |> List.map (\{ path } -> img [ class "layer-image", src path ] [])
                ]

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


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
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
