import "./main.css";
import { Elm } from "./Main.elm";
import * as serviceWorker from "./serviceWorker";

const names = require("./names.json");
let focusPoints = require("./focus-points.json");

async function main() {
    const response = await fetch("/focus-point-overrides.json");
    const contentType = response.headers.get("content-type");

    // If the content type is 'application/json' then it has successfully retrieved a json file with
    // some contents for use and we proceed to use them. If it is 'text/html' then no file has been
    // found and the create-elm-app framework is returning a copy of the index.html file in the hope
    // that that is the right thing to do.
    if (contentType.includes("application/json")) {
        const overrides = await response.json();
        focusPoints = [...focusPoints, ...overrides];
    }

    Elm.Main.init({
        node: document.getElementById("root"),
        flags: {
            windowWidth: window.innerWidth,
            windowHeight: window.innerHeight,
            names,
            focusPoints,
        },
    });
}

main();

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
