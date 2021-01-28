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
    { layers : SelectList String
    , offset : Point
    , dragState : DragState
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
                "/layers/mt.svg"
                [ "/layers/openweb.svg"
                , "/layers/openid.svg"
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
                ( { model | layers = SelectList.selectBy -1 model.layers |> Maybe.withDefault model.layers }, Cmd.none )

            else if List.member Keyboard.ArrowRight keys || List.member (Keyboard.Character "F") keys then
                ( { model | layers = SelectList.selectBy 1 model.layers |> Maybe.withDefault model.layers }, Cmd.none )

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
                        (\path -> img [ class "layer-image layer-past", src path, offsetX, offsetY ] [])
                , [ SelectList.selected model.layers ]
                    |> List.map (\path -> img [ class "layer-image layer-current", src path, offsetX, offsetY ] [])
                , SelectList.listAfter model.layers
                    |> List.map (\path -> img [ class "layer-image", src path, offsetX, offsetY ] [])
                ]
    in
    div [ class "layer-holder" ] layers



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
