#!/usr/bin/env python3

"""
EnTrance server process.
"""

import argparse
import enum
import logging
import pathlib
import random
import string
import sys
from dataclasses import dataclass
from pprint import pprint
from typing import Dict, List, Optional, Sequence

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
        "join_game": ["code", "?rounds", "?skips"],
        "submit_dares": ["dares"],
        "decision": ["accept"],
    }
    notifications: List[Optional[str]] = [
        None,
        "game_ready",
        "send_dares",
        "send_outcome",
    ]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.code: Optional[str] = None
        self.player_state: Optional[PlayerState] = None
        self.next_choice: Optional[bool] = None

    async def do_join_game(
        self, code: str, rounds: Optional[int], skips: Optional[int]
    ):
        if not code:
            self.code = "".join(
                random.choices(string.ascii_uppercase + string.digits, k=5)
            )
            if self.code in sessions:
                return self._rpc_failure(f"Code {self.code} already in use")
        else:
            self.code = code
        # Check game is available and compatible.
        if self.code in sessions:
            sess = sessions[self.code]
            if len(sess.players) >= 2:
                return self._rpc_failure(f"Game {self.code} already full")
            if rounds not in [sess.rounds, None] or skips not in [sess.skips, None]:
                return self._rpc_failure(
                    f"Requested game options (rounds={rounds}, skips={skips}) "
                    f"do not match existing game with code {self.code} "
                    f"(rounds={sess.rounds}, skips={sess.skips})"
                )
        else:
            if rounds is None:
                rounds = 8
            if skips is None:
                skips = 3
            logger.info("Creating game with id %r", self.code)
            sess = SessionState(code=self.code, rounds=rounds, skips=skips, players=[])
            sessions[self.code] = sess
        # Add player to game.
        logger.info("Player joining game with id %r", self.code)
        self.player_state = PlayerState(id=len(sess.players) + 1, feature=self)
        sess.players.append(self.player_state)
        pprint(sessions)
        if len(sess.players) == 2:
            for player in sessions[self.code].players:
                if player.feature is not None:
                    await player.feature.game_ready()
        else:
            return self._rpc_success(self.code)

    async def game_ready(self):
        sess = sessions[self.code]
        result = {
            **self._result(
                "game_ready",
                result={
                    "code": self.code,
                    "player_id": self.player_state.id,
                    "players": 2,
                    "rounds": sess.rounds,
                    "skips": sess.skips,
                },
            ),
            "channel": "app",
            "target": "defaultTarget",
            "userid": "default",
            "id": 1,
        }
        await self.ws_handler.notify(**result)

    async def do_submit_dares(self, dares: List[str]):
        self.player_state.submitted_dares = dares
        sess = sessions[self.code]
        if all(x.submitted_dares for x in sess.players):
            # All players have submitted dares, so shuffle and share them out.
            assert all(len(x.submitted_dares) == sess.rounds for x in sess.players)
            all_dares = [d for player in sess.players for d in player.submitted_dares]
            random.shuffle(all_dares)
            for i, player in enumerate(sess.players):
                allocated_dares = all_dares[i * sess.rounds : (i + 1) * sess.rounds]
                player.game_state = PlayerGameState(
                    allocated_dares, remaining_skips=sess.skips
                )
                if player.feature is None:
                    logger.debug("Player not connected to session %s", self.code)
                    continue
                await player.feature.send_dares(allocated_dares)

    async def send_dares(self, dares: List[str]):
        result = {
            **self._result("send_dares", result=dares),
            "channel": "app",
            "target": "defaultTarget",
            "userid": "default",
            "id": 1,
        }
        await self.ws_handler.notify(**result)

    async def do_decision(self, accept: bool):
        self.next_choice = accept
        sess = sessions[self.code]
        if all(player.feature.next_choice is not None for player in sess.players):
            # All players have chosen, so send the outcomes.
            for player in sess.players:
                await player.feature.send_outcome()
            for player in sess.players:
                player.feature.next_choice = None

    async def send_outcome(self):
        if all(feat.next_choice is True for feat in sessions[self.code]):
            outcome = "All players accepted, you must do the dare!"
        elif all(feat.next_choice is False for feat in sessions[self.code]):
            outcome = "All players refused, dares are skipped!"
        elif self.next_choice is False:
            outcome = "You refused, all players skip the dares!"
        else:
            outcome = "Another player refused, all players skip the dares!"
        result = {
            **self._result("send_outcome", result=outcome),
            "channel": "app",
            "target": "defaultTarget",
            "userid": "default",
            "id": 1,
        }
        await self.ws_handler.notify(**result)

    def close(self):
        if self.player_state:
            self.player_state.feature = None


# ------------------------------------------------------------------------------
# Session data management


class Choice(enum.Enum):
    ACCEPT = enum.auto()
    REFUSE = enum.auto()


@dataclass
class PlayerGameState:
    dares: List[str]
    remaining_skips: int
    next_dare_idx: int = 0
    next_dare_choice: Optional[Choice] = None


@dataclass
class PlayerState:
    id: int
    feature: Optional[GameFeature]
    submitted_dares: Sequence[str] = ()
    game_state: Optional[PlayerGameState] = None


@dataclass
class SessionState:
    code: str
    rounds: int
    skips: int
    players: List[PlayerState]


sessions: Dict[str, SessionState] = dict()


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

    @app.route("/<code:strorempty>")
    async def home_page(request: Request, code: Optional[str]):
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
    parser.add_argument("-p", "--port", type=int, help="Port to run on")
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
