---
title: "Tmux: how to run the same command in multiple panes"
date: 2024-01-30
tags: [tmux]
type: note
url: "/html/2024-01-30-tmux-run-same-command-in-multiple-panes.html"
---

# Why run the same command in multiple tmux panes?

Sometimes it can be convenient as a quick way to run some command in parallel on the server. We can still see the output, detach from tmux and disconnect
and reconnect later and attach to the tmux session to see the result.

# How to run the same command in multiple panes?

To run the same command in multiple panes, we can use a script like this:

```bash
#!/bin/bash

SESS='generation-jobs'
CMD='sleep 1 && echo "Hello, World\!"'
NUM_PANES=9 # 10 panes

# Create a new session named "$SESS"
tmux new-session -d -s $SESS

# Split the window into NUM_PANES panes
for i in $(seq 1 $NUM_PANES); do
  tmux split-window -v -t $SESS
  # Re-layout panes to be equally sized
  tmux select-layout -t $SESS tiled
done

# Set pane synchronization
tmux set-window-option -t $SESS:1 synchronize-panes on
# Run command in all panes
tmux send-keys -t $SESS "$CMD" Enter
# Attach to session named "$SESS"
tmux attach -t $SESS
```

It will work like this:

{{< video src="2024-01-30-tmux-run-same-command-in-multiple-panes.mp4" type="video/mp4">}}

Here is also a variation of the script that allows to add more panes to the existing session:

```
#!/bin/bash

SESS='generation-jobs'
CMD='sleep 1 && echo "Hello, World\!"'
NUM_PANES=$1  # Number of panes to add, specified as the first script argument
DELAY=5  # Delay in seconds

# Check if the tmux session exists
tmux has-session -t $SESS 2>/dev/null

if [ $? != 0 ]; then
  echo "Session $SESS does not exist, creating it..."
  # Create a new session named "$SESS"
  tmux new-session -d -s $SESS
  # Send the command to the newly created pane
  tmux send-keys -t $SESS "$CMD" Enter
  let NUM_PANES=NUM_PANES-1  # Decrease NUM_PANES by 1 because the first pane is already used
else
  echo "Session $SESS exists, adding panes to it..."
fi

# Create additional panes and start command in each pane with a delay
for i in $(seq 1 $NUM_PANES); do
  echo "."
  # Wait for DELAY seconds before starting the command
  sleep $DELAY
  
  # Split window and create a new pane
  tmux split-window -v -t $SESS
  # Even out the panes in the current window
  tmux select-layout -t $SESS tiled

  # Send the command to the newly created pane
  tmux send-keys -t $SESS "$CMD" Enter
done

# Attach to session named "$SESS"
tmux attach -t $SESS
```

# Related Links

[AskUbuntu: Open 8 panes of TMUX and go to different directory in each one , and run a command in each pane?](https://askubuntu.com/questions/1320470/open-8-panes-of-tmux-and-go-to-different-directory-in-each-one-and-run-a-comma)
[StackOverflow: TMUX: no space for new pane](https://stackoverflow.com/questions/68362719/tmux-no-space-for-new-pane)
