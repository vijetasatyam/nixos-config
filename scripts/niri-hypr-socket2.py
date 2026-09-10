#!/usr/bin/env python3
import json
import os
import re
import socket
import socketserver
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


def get_current_workspace_info():
    ws_list = get_niri_json(["workspaces"]) or []
    active_idx = 1
    max_idx = len(ws_list) if ws_list else 1
    for ws in ws_list:
        idx_val = ws.get("idx", ws.get("id", 1))
        if ws.get("is_active"):
            active_idx = idx_val
        if idx_val > max_idx:
            max_idx = idx_val
    return active_idx, max_idx, ws_list


# --- Event Broadcaster (.socket2.sock) ---
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


# --- Command & Query Handler (.socket.sock) ---
class HyprCmdHandler(socketserver.BaseRequestHandler):
    def handle(self):
        try:
            raw = self.request.recv(4096).decode("utf-8", errors="ignore").strip()
            if not raw:
                return

            if "monitors" in raw:
                outputs = get_niri_json(["outputs"]) or {}
                focused_win = get_niri_json(["focused-window"]) or {}
                is_fullscreen = bool(focused_win.get("is_fullscreen", False))
                active_idx, _, _ = get_current_workspace_info()

                monitors_payload = []
                idx = 0
                for name, out in outputs.items():
                    mode = out.get("current_mode") or {}
                    monitors_payload.append(
                        {
                            "id": idx,
                            "name": name,
                            "description": f"{out.get('make', '')} {out.get('model', '')}".strip(),
                            "make": out.get("make", "Unknown"),
                            "model": out.get("model", "Display"),
                            "serial": "",
                            "width": mode.get("width", 1920),
                            "height": mode.get("height", 1080),
                            "refreshRate": float(mode.get("refresh_rate", 60000))
                            / 1000.0,
                            "x": out.get("logical", {}).get("x", 0),
                            "y": out.get("logical", {}).get("y", 0),
                            "activeWorkspace": {
                                "id": active_idx,
                                "name": str(active_idx),
                                "hasfullscreen": is_fullscreen,
                            },
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
                            "activeWorkspace": {
                                "id": active_idx,
                                "name": str(active_idx),
                                "hasfullscreen": is_fullscreen,
                            },
                            "specialWorkspace": {"id": 0, "name": ""},
                            "focused": True,
                        }
                    ]
                resp = json.dumps(monitors_payload)

            elif "workspaces" in raw:
                active_idx, _, ws_list = get_current_workspace_info()
                focused_win = get_niri_json(["focused-window"]) or {}
                is_fullscreen = bool(focused_win.get("is_fullscreen", False))

                ws_payload = []
                for ws in ws_list:
                    ws_id = ws.get("id", 1)
                    idx_val = ws.get("idx", ws_id)
                    ws_payload.append(
                        {
                            "id": idx_val,
                            "name": str(idx_val),
                            "monitor": ws.get("output", "eDP-1"),
                            "windows": 0,
                            "hasfullscreen": (idx_val == active_idx) and is_fullscreen,
                        }
                    )
                if not ws_payload:
                    ws_payload = [
                        {"id": 1, "name": "1", "monitor": "eDP-1", "windows": 0}
                    ]
                resp = json.dumps(ws_payload)

            elif "clients" in raw:
                resp = "[]"

            elif "activewindow" in raw:
                win = get_niri_json(["focused-window"]) or {}
                fs = 2 if win.get("is_fullscreen", False) else 0
                active_idx, _, _ = get_current_workspace_info()
                resp = json.dumps(
                    {
                        "address": hex(win.get("id", 0)),
                        "mapped": True,
                        "hidden": False,
                        "at": [0, 0],
                        "size": [0, 0],
                        "workspace": {"id": active_idx, "name": str(active_idx)},
                        "floating": False,
                        "monitor": 0,
                        "class": win.get("app_id", ""),
                        "title": win.get("title", ""),
                        "initialClass": win.get("app_id", ""),
                        "initialTitle": win.get("title", ""),
                        "pid": 0,
                        "xwayland": False,
                        "pinned": False,
                        "fullscreen": fs,
                        "fullscreenClient": fs,
                    }
                )

            elif "dispatch workspace" in raw:
                target = raw.split()[-1].strip()
                active_idx, max_idx, _ = get_current_workspace_info()

                # Up-scroll / Prior workspace
                if any(x in target for x in ["-1", "e-", "m-", "r-", "prev"]):
                    if active_idx > 1:
                        subprocess.run(["niri", "msg", "action", "focus-workspace-up"])
                    else:
                        subprocess.run(
                            ["niri", "msg", "action", "focus-workspace", "1"]
                        )

                # Down-scroll / Next workspace (allows dynamic stepping)
                elif any(x in target for x in ["+1", "e+", "m+", "r+", "next"]):
                    subprocess.run(["niri", "msg", "action", "focus-workspace-down"])

                # Direct numeric workspace
                else:
                    digits = re.findall(r"\d+", target)
                    if digits:
                        target_num = int(digits[0])
                        # If requesting a higher workspace that doesn't exist yet, step down to create it
                        if target_num > max_idx:
                            steps = target_num - max_idx
                            for _ in range(steps):
                                subprocess.run(
                                    ["niri", "msg", "action", "focus-workspace-down"]
                                )
                        else:
                            subprocess.run(
                                [
                                    "niri",
                                    "msg",
                                    "action",
                                    "focus-workspace",
                                    str(target_num),
                                ]
                            )

                # Broadcast immediate sync
                new_idx, _, _ = get_current_workspace_info()
                broadcast(f"workspace>>{new_idx}")
                broadcast(f"focusedmon>>eDP-1,{new_idx}")
                resp = "ok"

            else:
                resp = "ok"

            self.request.sendall(resp.encode("utf-8"))
        except Exception:
            pass


class ThreadedUnixStreamServer(
    socketserver.ThreadingMixIn, socketserver.UnixStreamServer
):
    daemon_threads = True


def cmd_server_worker():
    if os.path.exists(CMD_SOCK):
        try:
            os.unlink(CMD_SOCK)
        except OSError:
            pass

    server = ThreadedUnixStreamServer(CMD_SOCK, HyprCmdHandler)
    server.serve_forever()


# --- Niri Event Stream Listener ---
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
            idx_val = ev["WorkspaceActivated"].get("idx", ws_id)
            broadcast(f"workspace>>{idx_val}")
            broadcast(f"focusedmon>>eDP-1,{idx_val}")

        elif "WindowFocusChanged" in ev:
            focus_info = ev["WindowFocusChanged"]
            if focus_info:
                title = focus_info.get("title") or ""
                app_id = focus_info.get("app_id") or ""
                is_fs = 1 if focus_info.get("is_fullscreen") else 0
                broadcast(f"activewindow>>{app_id},{title}")
                broadcast(f"activewindowv2>>{app_id}")
                broadcast(f"fullscreen>>{is_fs}")
            else:
                broadcast("activewindow>>,")
                broadcast("activewindowv2>>")
                broadcast("fullscreen>>0")

        elif "WorkspacesChanged" in ev:
            for ws in ev["WorkspacesChanged"].get("workspaces", []):
                ws_id = ws.get("id")
                idx_val = ws.get("idx", ws_id)
                if ws.get("is_active"):
                    broadcast(f"workspace>>{idx_val}")
                    broadcast(f"focusedmon>>eDP-1,{idx_val}")
                broadcast(f"createworkspace>>{idx_val}")


def main():
    os.makedirs(SOCKET_DIR, exist_ok=True)
    threading.Thread(target=event_server_worker, daemon=True).start()
    threading.Thread(target=cmd_server_worker, daemon=True).start()
    niri_event_worker()


if __name__ == "__main__":
    main()
