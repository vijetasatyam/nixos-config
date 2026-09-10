#!/usr/bin/env python3
import json
import os
import select
import shutil
import socket
import subprocess
import sys
import threading

SIGNATURE = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "niri-fake-hypr")
SOCKET_DIR = f"/tmp/hypr/{SIGNATURE}"
SOCKET_PATH = f"{SOCKET_DIR}/.socket2.sock"

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


def server_worker():
    if os.path.exists(SOCKET_PATH):
        try:
            os.unlink(SOCKET_PATH)
        except OSError:
            pass

    os.makedirs(SOCKET_DIR, exist_ok=True)
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCKET_PATH)
    server.listen(16)

    while True:
        try:
            conn, _ = server.accept()
            with clients_lock:
                clients.add(conn)
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

        # 1. Workspace Activated
        if "WorkspaceActivated" in ev:
            ws_id = ev["WorkspaceActivated"].get("id", 1)
            broadcast(f"workspace>>{ws_id}")

        # 2. Window Focus Changed
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

        # 3. Workspaces Changed (Created/Removed)
        elif "WorkspacesChanged" in ev:
            for ws in ev["WorkspacesChanged"].get("workspaces", []):
                ws_id = ws.get("id")
                if ws.get("is_active"):
                    broadcast(f"workspace>>{ws_id}")
                broadcast(f"createworkspace>>{ws_id}")


def main():
    threading.Thread(target=server_worker, daemon=True).start()
    niri_event_worker()


if __name__ == "__main__":
    main()
