port module Main exposing (..)

import Browser
import Html exposing (Html, a, button, div, img, span, text)
import Html.Attributes exposing (href, src, style)
import Html.Events exposing (onClick)
import Json.Decode as Decode


type alias Model =
    { githubUrl : String
    , avatarSrc : String
    , followers : Int
    }


initialModel : Model
initialModel =
    { githubUrl = ""
    , avatarSrc = ""
    , followers = 0
    }


type Msg
    = CallJsonp
    | SetData (Result Decode.Error Model)


-- Sending port
port execJsonp : String -> Cmd msg


-- Receiving port
port jsonpCallback : (Decode.Value -> msg) -> Sub msg


-- Kudos goes to https://medium.com/@_rchaves_/elm-how-to-use-decoders-for-ports-how-to-not-use-decoders-for-json-a4f95b51473a
decodeGithubUserData : Decode.Value -> Result Decode.Error Model
decodeGithubUserData =
    Decode.decodeValue
        ( Decode.map3 Model
            (Decode.at ["data", "html_url"] Decode.string)
            (Decode.at ["data", "avatar_url"] Decode.string)
            (Decode.at ["data", "followers"] Decode.int)
        )


subscriptions : Model -> Sub Msg
subscriptions model =
    jsonpCallback (decodeGithubUserData >> SetData)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CallJsonp ->
            ( model, execJsonp "https://api.github.com/users/stormont?callback=jsonpCallback" )
        
        SetData (Err _) ->
            ( model, Cmd.none )
        
        SetData (Ok m) ->
            ( m, Cmd.none )


view : Model -> Html Msg
view model =
    if String.length model.githubUrl > 0
        then 
            div []
                [ div []
                    [ span [] [ text "Github URL:" ]
                    , span [] [ a [ href model.githubUrl ] [ text model.githubUrl ] ]
                    ]
                , div [] [ img [ src model.avatarSrc, style "height" "64px" ] [] ]
                , div [] [ text <| "Followers: " ++ String.fromInt model.followers ]
                ]
        else
            button [ onClick CallJsonp ] [ text "Get Data" ]


init : flags -> ( Model, Cmd Msg )
init _ =
    ( initialModel, Cmd.none )


main : Program () Model Msg
main =
    Browser.element
      { init = init
      , subscriptions = subscriptions
      , update = update
      , view = view
      }
