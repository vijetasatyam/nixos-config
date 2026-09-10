#!/usr/bin/env python3
import json
import os
import re
import socket
import socketserver
import subprocess
import threading

SIGNATURE = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "niri-fake-hypr")
XDG_RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")

# Setup multiple target directories for maximum compatibility with Quickshell
TARGET_DIRS = [
    f"/tmp/hypr/{SIGNATURE}",
    f"{XDG_RUNTIME_DIR}/hypr/{SIGNATURE}",
    f"/tmp/hypr",
    f"{XDG_RUNTIME_DIR}/hypr",
]

EVENT_SOCK = f"/tmp/hypr/{SIGNATURE}/.socket2.sock"
CMD_SOCK = f"/tmp/hypr/{SIGNATURE}/.socket.sock"

clients = set()
clients_lock = threading.Lock()


def sync_socket_links():
    """Ensure sockets are mirrored across all locations Quickshell might check."""
    for d in TARGET_DIRS:
        os.makedirs(d, exist_ok=True)

    for sock in [".socket.sock", ".socket2.sock"]:
        src = f"/tmp/hypr/{SIGNATURE}/{sock}"
        for d in TARGET_DIRS:
            dst = f"{d}/{sock}"
            if dst != src:
                try:
                    if os.path.exists(dst) or os.path.islink(dst):
                        os.unlink(dst)
                    os.symlink(src, dst)
                except OSError:
                    pass


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


def get_workspace_state():
    niri_ws = get_niri_json(["workspaces"]) or []
    active_idx = 1
    indices = []

    for ws in niri_ws:
        idx_val = ws.get("idx", ws.get("id", 1))
        indices.append(idx_val)
        if ws.get("is_active"):
            active_idx = idx_val

    if not indices:
        indices = [1]

    indices = sorted(list(set(indices)))
    return active_idx, max(indices), indices


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

    sync_socket_links()

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

            active_idx, max_idx, ws_indices = get_workspace_state()
            focused_win = get_niri_json(["focused-window"]) or {}
            is_fullscreen = bool(focused_win.get("is_fullscreen", False))

            if "monitors" in raw:
                outputs = get_niri_json(["outputs"]) or {}
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
                                "id": int(active_idx),
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
                                "id": int(active_idx),
                                "name": str(active_idx),
                                "hasfullscreen": is_fullscreen,
                            },
                            "specialWorkspace": {"id": 0, "name": ""},
                            "focused": True,
                        }
                    ]
                resp = json.dumps(monitors_payload)

            elif "workspaces" in raw:
                all_ids = sorted(list(set(ws_indices + [active_idx])))
                ws_payload = [
                    {
                        "id": int(i),
                        "name": str(i),
                        "monitor": "eDP-1",
                        "windows": 0,
                        "hasfullscreen": (i == active_idx) and is_fullscreen,
                    }
                    for i in all_ids
                ]
                resp = json.dumps(ws_payload)

            elif "clients" in raw:
                resp = "[]"

            elif "activewindow" in raw:
                fs = 2 if is_fullscreen else 0
                resp = json.dumps(
                    {
                        "address": hex(focused_win.get("id", 0)),
                        "mapped": True,
                        "hidden": False,
                        "at": [0, 0],
                        "size": [0, 0],
                        "workspace": {"id": int(active_idx), "name": str(active_idx)},
                        "floating": False,
                        "monitor": 0,
                        "class": focused_win.get("app_id", ""),
                        "title": focused_win.get("title", ""),
                        "initialClass": focused_win.get("app_id", ""),
                        "initialTitle": focused_win.get("title", ""),
                        "pid": 0,
                        "xwayland": False,
                        "pinned": False,
                        "fullscreen": fs,
                        "fullscreenClient": fs,
                    }
                )

            elif "dispatch workspace" in raw:
                target = raw.split()[-1].strip()

                # Up-scroll (Caelestia dispatches "workspace r-1")
                if any(x in target for x in ["r-1", "e-1", "m-1", "-", "prev"]):
                    subprocess.run(["niri", "msg", "action", "focus-workspace-up"])

                # Down-scroll (Caelestia dispatches "workspace r+1")
                elif any(x in target for x in ["r+1", "e+1", "m+1", "+", "next"]):
                    subprocess.run(["niri", "msg", "action", "focus-workspace-down"])

                # Numerical jump
                else:
                    digits = re.findall(r"\d+", target)
                    if digits:
                        num = int(digits[0])
                        if num > max_idx:
                            for _ in range(num - max_idx):
                                subprocess.run(
                                    ["niri", "msg", "action", "focus-workspace-down"]
                                )
                        else:
                            subprocess.run(
                                ["niri", "msg", "action", "focus-workspace", str(num)]
                            )

                new_idx, _, _ = get_workspace_state()
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
    os.makedirs(f"/tmp/hypr/{SIGNATURE}", exist_ok=True)
    if os.path.exists(CMD_SOCK):
        try:
            os.unlink(CMD_SOCK)
        except OSError:
            pass

    server = ThreadedUnixStreamServer(CMD_SOCK, HyprCmdHandler)
    sync_socket_links()
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
            active_idx, _, _ = get_workspace_state()
            broadcast(f"workspace>>{active_idx}")
            broadcast(f"focusedmon>>eDP-1,{active_idx}")
            for ws in ev["WorkspacesChanged"].get("workspaces", []):
                idx_val = ws.get("idx", ws.get("id", 1))
                broadcast(f"createworkspace>>{idx_val}")


def main():
    sync_socket_links()
    threading.Thread(target=event_server_worker, daemon=True).start()
    threading.Thread(target=cmd_server_worker, daemon=True).start()
    niri_event_worker()


if __name__ == "__main__":
    main()
