// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.css";
import "../node_modules/aos/dist/aos.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html";
import "aos";
import * as Aos from "aos";

window.onload = () => {
    const aos_ret = Aos.init({
        duration: 200,
        easing: 'ease-in-sine',
    });
    console.log(aos_ret);
}
