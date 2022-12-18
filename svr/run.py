#!/usr/bin/env python3
"""
EnTrance server process.
"""

import argparse
import asyncio
import logging
import pathlib
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
        "submit_dares": ["code", "dares"],
    }
    notifications: List[Optional[str]] = [
        None,
        "collect_dares",
    ]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.id = None

    async def do_submit_dares(self, code: str, dares: List[str]):
        self.id = code
        active_games[code].append(self)
        pprint(active_games)
        await asyncio.gather(
            *(player.collect_dares(dares) for player in active_games[code])
        )

    async def collect_dares(self, dares: List[str]):
        result = {
            **self._result("collect_dares", result=dares),
            "id": 1,
            "target": "defaultTarget",
            "channel": "app",
            "userid": "default",
        }
        await self.ws_handler.notify(**result)

    def close(self):
        if self.id:
            active_games[self.id].remove(self)


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
