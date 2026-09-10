#!/usr/bin/env bash

# Wait until caelestia-shell IPC socket is ready
while ! caelestia-shell ipc call ping >/dev/null 2>&1; do
    sleep 0.5
done

# Stream Niri workspace and window events
niri msg -j event-stream | while read -r line; do
    # Workspace change
    ws_id=$(echo "$line" | jq -r '.WorkspaceActivated.id // empty')
    if [ -n "$ws_id" ]; then
        caelestia-shell ipc call workspaces setActive "$ws_id" 2>/dev/null || true
    fi

    # Window title focus change
    title=$(echo "$line" | jq -r '.WindowFocusChanged.title // empty')
    if [ -n "$title" ]; then
        caelestia-shell ipc call bar setWindowTitle "$title" 2>/dev/null || true
    fi
done
