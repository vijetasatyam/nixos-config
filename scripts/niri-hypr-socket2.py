#!/usr/bin/env python3
import json
import os
import socket
import subprocess
import threading

SIGNATURE = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "niri-fake-hypr")
SOCKET_DIR = f"/tmp/hypr/{SIGNATURE}"
EVENT_SOCK = f"{SOCKET_DIR}/.socket2.sock"
CMD_SOCK = f"{SOCKET_DIR}/.socket.sock"

clients = set()
clients_lock = threading.Lock()


def get_niri_json(subcommand: list):
    try:
        res = subprocess.run(
            ["niri", "msg", "-j"] + subcommand,
            capture_output=True,
            text=True,
            check=True,
        )
        return json.loads(res.stdout)
    except Exception:
        return None


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
            raw = conn.recv(1024).decode("utf-8", errors="ignore").strip()

            if "monitors" in raw:
                outputs = get_niri_json(["outputs"]) or {}
                monitors_payload = []
                idx = 0
                for name, out in outputs.items():
                    monitors_payload.append(
                        {
                            "id": idx,
                            "name": name,
                            "description": out.get("make", "")
                            + " "
                            + out.get("model", ""),
                            "make": out.get("make", "Unknown"),
                            "model": out.get("model", "Display"),
                            "serial": "",
                            "width": out.get("current_mode", {}).get("width", 1920),
                            "height": out.get("current_mode", {}).get("height", 1080),
                            "refreshRate": float(
                                out.get("current_mode", {}).get("refresh_rate", 60000)
                            )
                            / 1000.0,
                            "x": out.get("logical", {}).get("x", 0),
                            "y": out.get("logical", {}).get("y", 0),
                            "activeWorkspace": {"id": 1, "name": "1"},
                            "specialWorkspace": {"id": 0, "name": ""},
                            "focused": True,
                        }
                    )
                    idx += 1
                if not monitors_payload:
                    monitors_payload = [
                        {
                            "id": 0,
                            "name": "eDP-1",
                            "description": "Display",
                            "make": "Unknown",
                            "model": "Display",
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
                resp = json.dumps(monitors_payload)

            elif "workspaces" in raw:
                niri_ws = get_niri_json(["workspaces"]) or []
                ws_payload = []
                for ws in niri_ws:
                    ws_payload.append(
                        {
                            "id": ws.get("id", 1),
                            "name": str(ws.get("idx", ws.get("id", 1))),
                            "monitor": ws.get("output", "eDP-1"),
                            "windows": 0,
                        }
                    )
                if not ws_payload:
                    ws_payload = [
                        {"id": 1, "name": "1", "monitor": "eDP-1", "windows": 0}
                    ]
                resp = json.dumps(ws_payload)

            elif "activewindow" in raw:
                win = get_niri_json(["focused-window"]) or {}
                resp = json.dumps(
                    {
                        "address": hex(win.get("id", 0)),
                        "mapped": True,
                        "hidden": False,
                        "at": [0, 0],
                        "size": [0, 0],
                        "workspace": {"id": 1, "name": "1"},
                        "floating": False,
                        "monitor": 0,
                        "class": win.get("app_id", ""),
                        "title": win.get("title", ""),
                        "initialClass": win.get("app_id", ""),
                        "initialTitle": win.get("title", ""),
                        "pid": 0,
                        "xwayland": False,
                        "pinned": False,
                        "fullscreen": 0,
                        "fullscreenClient": 0,
                    }
                )

            elif "dispatch workspace" in raw:
                target = raw.split()[-1]
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
