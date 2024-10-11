#!/bin/bash

COMMANDS=$(cat <<'EOF'
EOF
)

while IFS= read -r command; do
    if [[ -n "$command" ]]; then
        tmux send-keys -t arch-vm-base "$command" C-m
        sleep 1
    fi
done <<< "$COMMANDS"

COMMANDS=$(cat <<EOF 
EOF
)

tmux send-keys -t arch-vm-base "$COMMANDS" C-m
