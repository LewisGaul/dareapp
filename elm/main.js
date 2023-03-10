'use strict';

// Compute the URL of the websocket
const dev_mode = process.env.NODE_ENV !== 'production';
const ws_proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
const url_port = dev_mode ? 5000 : location.port;
const ws_url = `${ws_proto}//${location.hostname}:${url_port}/ws`;

// Initialise the Elm app
import { Elm } from './src/Main.elm';
const basePath = "/";
const app = Elm.Main.init({
  node: document.querySelector('main'),
  flags: { basePath },
});

// Do the websocket stuff
import { handleWebsocket } from 'entrance-ws';
handleWebsocket(ws_url, app);
