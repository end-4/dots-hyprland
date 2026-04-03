#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import socket


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Send an Orbitbar event")
    parser.add_argument("--socket-path", required=True)
    parser.add_argument("--tool", required=True)
    parser.add_argument("--session", dest="session_id", required=True)
    parser.add_argument("--status", required=True)
    parser.add_argument("--title")
    parser.add_argument("--detail")
    parser.add_argument("--project")
    parser.add_argument("--cwd")
    parser.add_argument("--workspace")
    parser.add_argument("--recent", action="append", default=[])
    parser.add_argument("--preview")
    parser.add_argument("--actions-json")
    parser.add_argument("--options-json")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    payload = {
        "tool": args.tool,
        "session_id": args.session_id,
        "status": args.status,
    }

    optional = {
        "title": args.title,
        "detail": args.detail,
        "project": args.project,
        "cwd": args.cwd,
        "workspace": args.workspace,
        "recent": args.recent or None,
        "preview": args.preview,
        "actions": json.loads(args.actions_json) if args.actions_json else None,
        "options": json.loads(args.options_json) if args.options_json else None,
    }
    payload.update({key: value for key, value in optional.items() if value is not None})

    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    client.connect(args.socket_path)
    client.sendall(json.dumps(payload).encode("utf-8") + b"\n")
    response = client.recv(4096).decode("utf-8").strip()
    print(response)
    client.close()


if __name__ == "__main__":
    main()
