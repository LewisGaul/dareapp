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
        "next_round": ["__req__"],
        "decision": ["accept", "__req__"],
    }
    notifications: List[Optional[str]] = [
        None,
        "start_entry_phase",
        "start_game_phase",
        "next_dare",
        "outcome",
    ]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.code: Optional[str] = None
        self.player_state: Optional[PlayerState] = None
        self.next_choice: Optional[bool] = None
        self._channel_id = 1

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
            await sess.start_entry_phase()
        else:
            return self._rpc_success(self.code)

    async def start_entry_phase(self):
        sess = sessions[self.code]
        result = {
            **self._result(
                "start_entry_phase",
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
            await sess.share_out_dares_and_start_game()
        else:
            return self._rpc_success()

    async def start_game_phase(self, rounds: int, skips: int):
        result = {
            **self._result(
                "start_game_phase",
                result={
                    "players": 2,
                    "rounds": rounds,
                    "skips": skips,
                },
            ),
            "channel": "app",
            "target": "defaultTarget",
            "userid": "default",
            "id": 1,
        }
        await self.ws_handler.notify(**result)

    async def do_next_round(self, req):
        # Snoop the channel ID so that we can send notifications...
        self._get_channel_id(req)
        self.player_state.game_state.waiting = True
        sess = sessions[self.code]
        if all(p.game_state.waiting for p in sess.players):
            await sess.send_next_round_of_dares()

    async def send_next_dare(self, round: int, dare: str):
        result = {
            **self._result(
                "next_dare",
                result={
                    "round": round,
                    "dare": dare,
                },
            ),
            "channel": "gameplay_page",
            "target": "defaultTarget",
            "userid": "default",
            "id": self._channel_id,
        }
        await self.ws_handler.notify(**result)

    async def do_decision(self, accept: bool, req):
        # Snoop the channel ID so that we can send notifications...
        self._get_channel_id(req)
        self.player_state.game_state.next_dare_choice = (
            Choice.ACCEPT if accept else Choice.REFUSE
        )
        sess = sessions[self.code]
        if all(
            player.game_state.next_dare_choice is not None for player in sess.players
        ):
            await sess.send_round_outcomes()

    async def send_outcome(self, message: str):
        result = {
            **self._result("outcome", result=message),
            "channel": "gameplay_page",
            "target": "defaultTarget",
            "userid": "default",
            "id": self._channel_id,
        }
        await self.ws_handler.notify(**result)

    def close(self):
        if self.player_state:
            self.player_state.feature = None

    def _get_channel_id(self, req):
        self._channel_id = req["id"]


# ------------------------------------------------------------------------------
# Session data management


class Choice(enum.Enum):
    ACCEPT = enum.auto()
    REFUSE = enum.auto()


@dataclass
class PlayerGameState:
    dares: List[str]
    remaining_skips: int
    next_dare_choice: Optional[Choice] = None
    waiting: bool = False


@dataclass
class PlayerState:
    id: int
    feature: Optional[GameFeature]
    submitted_dares: Sequence[str] = ()
    game_state: Optional[PlayerGameState] = None


@dataclass
class SessionGameState:
    next_dare_idx: int = 0


@dataclass
class SessionState:
    code: str
    rounds: int
    skips: int
    players: List[PlayerState]
    game_state: Optional[SessionGameState] = None

    async def start_entry_phase(self):
        for player in self.players:
            if player.feature is not None:
                await player.feature.start_entry_phase()

    async def share_out_dares_and_start_game(self):
        self.game_state = SessionGameState()
        logger.info("Sharing out dares in session %s", self.code)
        assert all(len(x.submitted_dares) == self.rounds for x in self.players)
        all_dares = [d for player in self.players for d in player.submitted_dares]
        random.shuffle(all_dares)
        for i, player in enumerate(self.players):
            allocated_dares = all_dares[i * self.rounds : (i + 1) * self.rounds]
            player.game_state = PlayerGameState(
                allocated_dares, remaining_skips=self.skips
            )
            if player.feature is None:
                logger.debug(
                    "Player %d not connected to session %s", player.id, self.code
                )
                continue
            await player.feature.start_game_phase(self.rounds, self.skips)

    async def send_next_round_of_dares(self):
        logger.info(
            "Sending round %s of dares in session %s",
            self.game_state.next_dare_idx + 1,
            self.code,
        )
        assert self.game_state.next_dare_idx < self.rounds
        for player in self.players:
            assert player.game_state is not None
            if player.feature is None:
                logger.debug(
                    "Player %d not connected to session %s", player.id, self.code
                )
                continue
            player.game_state.waiting = False
            await player.feature.send_next_dare(
                self.game_state.next_dare_idx + 1,
                player.game_state.dares[self.game_state.next_dare_idx],
            )

    async def send_round_outcomes(self):
        logger.info(
            "Sending outcomes for round %s in session %s",
            self.game_state.next_dare_idx + 1,
            self.code,
        )
        assert self.game_state.next_dare_idx < self.rounds
        for player in self.players:
            assert player.game_state is not None
            if player.feature is None:
                logger.debug(
                    "Player %d not connected to session %s", player.id, self.code
                )
                continue
            player.game_state.waiting = False
            # Send the appropriate outcome message.
            opponent = [p for p in self.players if p is not player][0]
            opponent_dare = opponent.game_state.dares[self.game_state.next_dare_idx]
            if all(
                p.game_state.next_dare_choice is Choice.ACCEPT
                for p in [player, opponent]
            ):
                outcome = (
                    "All players accepted, you must do your dare and your "
                    f"opponent must do: {opponent_dare!r}"
                )
            elif all(
                p.game_state.next_dare_choice is Choice.REFUSE
                for p in [player, opponent]
            ):
                outcome = (
                    f"All players refused (opponent had {opponent_dare!r}), "
                    "dares are skipped"
                )
            elif player.game_state.next_dare_choice is Choice.REFUSE:
                outcome = (
                    f"You refused, your opponent may skip their dare "
                    f"{opponent_dare!r}"
                )
            else:
                outcome = (
                    f"Opponent refused to do {opponent_dare!r}, you may skip "
                    "your dare"
                )
            await player.feature.send_outcome(outcome)
        for player in self.players:
            player.game_state.next_dare_choice = None
        self.game_state.next_dare_idx += 1
        if self.game_state.next_dare_idx == self.rounds:
            # Game is finished.
            sessions.pop(self.code)


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

    @app.route(r"/<code_or_file:strorempty>")
    async def home_page(request: Request, code_or_file: Optional[str]):
        if (static_dir / code_or_file).is_file():
            return await sanic.response.file(
                str(static_dir / code_or_file), headers=common_header
            )
        else:
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
