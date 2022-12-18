#!/usr/bin/env python3
"""
EnTrance server process.
"""

import argparse
import logging
import pathlib
import random
import sys
from collections import defaultdict
from pprint import pprint
from typing import Dict, List, Optional

import entrance
import sanic
import sanic.exceptions
import sanic.response
import yaml
from sanic.request import Request


logger = logging.getLogger(__name__)

SVR_DIR = pathlib.Path(__file__).resolve().parent
PROJECT_ROOT = SVR_DIR.parent


# ------------------------------------------------------------------------------
# Features


class GameFeature(entrance.ConfiguredFeature):
    """EnTrance configured feature for the dare app."""

    name = "dare_app"

    requests: Dict[str, List[str]] = {
        "join_game": ["?code"],
        "submit_dares": ["dares"],
    }
    notifications: List[Optional[str]] = [
        None,
        "send_dares",
    ]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.code: Optional[str] = None
        self.dares: List[str] = []

    async def do_join_game(self, code: Optional[str] = None):
        if code is None:
            self.code = random.randbytes(5)
            if self.code in active_games:
                return self._rpc_failure(f"Code {self.code} already in use")
        else:
            self.code = code
            if len(active_games[self.code]) >= 2:
                return self._rpc_failure(f"Game {self.code} already full")
        active_games[self.code].append(self)

    async def do_submit_dares(self, dares: List[str]):
        self.dares = dares
        pprint(active_games[self.code])
        pprint([x.dares for x in active_games[self.code]])
        if all(x.dares for x in active_games[self.code]):
            # All players have submitted dares, so shuffle and share them out.
            assert all(len(x.dares) == 10 for x in active_games[self.code])
            all_dares = [d for feat in active_games[self.code] for d in feat.dares]
            random.shuffle(all_dares)
            for i, feat in enumerate(active_games[self.code]):
                feat.dares = all_dares[i * 10 : (i + 1) * 10]
                await feat.send_dares()

    async def send_dares(self):
        result = {
            **self._result("send_dares", result=self.dares),
            "channel": "app",
        }
        await self.ws_handler.notify(**result)

    def close(self):
        if self.code:
            active_games[self.code].remove(self)
            if len(active_games[self.code]) == 0:
                active_games.pop(self.code)


active_games: Dict[str, List[GameFeature]] = defaultdict(list)


# ------------------------------------------------------------------------------
# Startup


def start(config):
    """
    Start a simple server with the specified configuration.
    """
    start_cfg = config["start"]
    logger.info(
        "Starting app with %s",
        ", ".join(["{}={}".format(k, v) for k, v in start_cfg.items()]),
    )
    app = sanic.Sanic(name="Dare_app", log_config=None)
    app.config.RESPONSE_TIMEOUT = 3600
    app.config.KEEP_ALIVE_TIMEOUT = 75

    common_header = {
        "Cache-Control": "no-store, must-revalidate",
        "Pragma": "no-cache",
        "Expires": "0",
    }

    # Websocket handling
    @app.websocket("/ws")
    async def handle_ws(request: Request, ws):
        logger.info("New websocket client")
        ws_handler = entrance.WebsocketHandler(ws, config["features"])
        await ws_handler.handle_incoming_requests()

    # Static file handling
    static_dir = SVR_DIR / start_cfg["static_dir"]

    @app.route("/")
    async def home_page(request: Request):
        return await sanic.response.file(
            str(static_dir / "index.html"), headers=common_header
        )

    # This must come after the dynamically handled routes.
    app.static("/", str(static_dir))

    @app.exception(sanic.exceptions.NotFound)
    @app.exception(sanic.exceptions.FileNotFound)
    async def not_found(request: Request, exception: Exception):
        logger.info("Not found: %s", request.path)
        return sanic.response.redirect("/")

    # Enter event loop
    app.run(host=start_cfg["host"], port=start_cfg["port"])


def parse_args(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--port", help="Port to run on")
    parser.add_argument("-a", "--addr", help="Bind address")
    parser.add_argument(
        "-d", "--debug", action="store_true", help="Turn on debug logging"
    )
    return parser.parse_args(argv)


def main(argv):
    args = parse_args(argv)

    with open(SVR_DIR / "config.yml") as f:
        config = yaml.safe_load(f.read())

    if args.debug:
        config["logging"]["handlers"]["console"]["level"] = "DEBUG"

    if args.port:
        config["start"]["port"] = args.port

    if args.addr:
        config["start"]["host"] = args.addr

    # Startup
    logging.config.dictConfig(config["logging"])
    start(config)
    logger.info("Closing down gracefully")


if __name__ == "__main__":
    main(sys.argv[1:])