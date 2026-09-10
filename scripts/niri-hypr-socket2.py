#!/usr/bin/env python3
import json
import os
import select
import socket
import subprocess
import sys
import threading

SIGNATURE = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "niri-fake-hypr")
SOCKET_DIR = f"/tmp/hypr/{SIGNATURE}"
EVENT_SOCK = f"{SOCKET_DIR}/.socket2.sock"
CMD_SOCK = f"{SOCKET_DIR}/.socket.sock"

clients = set()
clients_lock = threading.Lock()


def broadcast(msg: str):
    payload = (msg.strip() + "\n").encode("utf-8")
    with clients_lock:
        to_remove = set()
        for client in clients:
            try:
                client.sendall(payload)
            except (BrokenPipeError, ConnectionResetError, OSError):
                to_remove.add(client)
        clients.difference_update(to_remove)


def event_server_worker():
    if os.path.exists(EVENT_SOCK):
        try:
            os.unlink(EVENT_SOCK)
        except OSError:
            pass

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(EVENT_SOCK)
    server.listen(16)

    while True:
        try:
            conn, _ = server.accept()
            with clients_lock:
                clients.add(conn)
        except Exception:
            break


def cmd_server_worker():
    """Responds to Caelestia's queries for initial state (monitors, workspaces, etc.)"""
    if os.path.exists(CMD_SOCK):
        try:
            os.unlink(CMD_SOCK)
        except OSError:
            pass

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(CMD_SOCK)
    server.listen(16)

    while True:
        try:
            conn, _ = server.accept()
            data = conn.recv(1024).decode("utf-8", errors="ignore").strip()

            # Handle requests Caelestia sends on startup
            if "monitors" in data:
                # Return dummy monitor matching default output
                resp = json.dumps(
                    [
                        {
                            "id": 0,
                            "name": "eDP-1",
                            "description": "Built-in Display",
                            "make": "Unknown",
                            "model": "Unknown",
                            "serial": "",
                            "width": 1920,
                            "height": 1080,
                            "refreshRate": 60.0,
                            "x": 0,
                            "y": 0,
                            "activeWorkspace": {"id": 1, "name": "1"},
                            "specialWorkspace": {"id": 0, "name": ""},
                            "focused": True,
                        }
                    ]
                )
            elif "workspaces" in data:
                resp = json.dumps(
                    [
                        {"id": i, "name": str(i), "monitor": "eDP-1", "windows": 1}
                        for i in range(1, 6)
                    ]
                )
            elif "activewindow" in data:
                resp = json.dumps(
                    {
                        "address": "0x0",
                        "mapped": True,
                        "hidden": False,
                        "at": [0, 0],
                        "size": [1920, 1080],
                        "workspace": {"id": 1, "name": "1"},
                        "floating": False,
                        "monitor": 0,
                        "class": "",
                        "title": "",
                        "initialClass": "",
                        "initialTitle": "",
                        "pid": 0,
                        "xwayland": False,
                        "pinned": False,
                        "fullscreen": 0,
                        "fullscreenClient": 0,
                    }
                )
            elif "dispatch workspace" in data:
                # Caelestia clicked a workspace button
                target = data.split()[-1]
                subprocess.Popen(["niri", "msg", "action", "focus-workspace", target])
                resp = "ok"
            else:
                resp = "ok"

            conn.sendall(resp.encode("utf-8"))
            conn.close()
        except Exception:
            break


def niri_event_worker():
    cmd = ["niri", "msg", "-j", "event-stream"]
    proc = subprocess.Popen(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True
    )

    for line in iter(proc.stdout.readline, ""):
        if not line:
            break
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            continue

        if "WorkspaceActivated" in ev:
            ws_id = ev["WorkspaceActivated"].get("id", 1)
            broadcast(f"workspace>>{ws_id}")

        elif "WindowFocusChanged" in ev:
            focus_info = ev["WindowFocusChanged"]
            if focus_info:
                title = focus_info.get("title") or ""
                app_id = focus_info.get("app_id") or ""
                broadcast(f"activewindow>>{app_id},{title}")
                broadcast(f"activewindowv2>>{app_id}")
            else:
                broadcast("activewindow>>,")
                broadcast("activewindowv2>>")

        elif "WorkspacesChanged" in ev:
            for ws in ev["WorkspacesChanged"].get("workspaces", []):
                ws_id = ws.get("id")
                if ws.get("is_active"):
                    broadcast(f"workspace>>{ws_id}")
                broadcast(f"createworkspace>>{ws_id}")


def main():
    os.makedirs(SOCKET_DIR, exist_ok=True)
    threading.Thread(target=event_server_worker, daemon=True).start()
    threading.Thread(target=cmd_server_worker, daemon=True).start()
    niri_event_worker()


if __name__ == "__main__":
    main()
