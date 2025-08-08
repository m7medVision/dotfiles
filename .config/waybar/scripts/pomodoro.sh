#!/bin/bash

# --- CONFIGURATION ---
WORK_MINS=25
BREAK_MINS=5
STATE_FILE="/tmp/pomodoro_state"
END_TIME_FILE="/tmp/pomodoro_end_time"

# --- FUNCTIONS ---
start_session() {
    local duration_mins=$1
    local new_state=$2
    echo "$new_state" > "$STATE_FILE"
    current_time=$(date +%s)
    end_time=$((current_time + duration_mins * 60))
    echo "$end_time" > "$END_TIME_FILE"
}

notify() {
    notify-send "Pomodoro" "$1" -u normal
}

# --- SCRIPT LOGIC ---

# Part 1: Handle clicks from Waybar ('toggle' argument)
if [ "$1" = "toggle" ]; then
    if [ ! -f "$STATE_FILE" ]; then
        start_session $WORK_MINS "work"
        notify "Work session started for $WORK_MINS minutes."
    else
        rm -f "$STATE_FILE" "$END_TIME_FILE"
        notify "Pomodoro timer stopped."
    fi
    # After a click, tell Waybar to refresh its modules
    pkill -RTMIN+8 waybar
    exit 0
fi

# Part 2: Display status (this runs every second via Waybar's "interval")
# If state files don't exist, it means the timer is off.
if [ ! -f "$STATE_FILE" ] || [ ! -f "$END_TIME_FILE" ]; then
    echo "{\"text\":\" Off\", \"class\":\"idle\", \"tooltip\":\"Click to start Pomodoro\"}"
    exit 0
fi

# Read the state and calculate remaining time
state=$(cat "$STATE_FILE")
end_time=$(cat "$END_TIME_FILE")
current_time=$(date +%s)
remaining_seconds=$((end_time - current_time))

# Part 3: Handle the moment the timer finishes
if [ "$remaining_seconds" -le 0 ]; then
    if [ "$state" = "work" ]; then
        # Work session ended, so start a break
        start_session $BREAK_MINS "break"
        notify "Time for a break! Locking screen for $BREAK_MINS minutes."
        playerctl -a pause 2>/dev/null & # Pause media in the background
        hyprlock & # Lock the screen in the background
    else
        # Break session ended, so turn the timer off
        rm -f "$STATE_FILE" "$END_TIME_FILE"
        notify "Break is over! Time to get back to work."
    fi
    # Tell Waybar to refresh immediately to show the new state
    pkill -RTMIN+8 waybar
    exit 0
fi

# Part 4: Display the running timer
mins=$((remaining_seconds / 60))
secs=$((remaining_seconds % 60))
time_format=$(printf "%02d:%02d" $mins $secs)

if [ "$state" = "work" ]; then
    icon=""
    tooltip="Work: $time_format remaining"
    class="work"
else
    icon=""
    tooltip="Break: $time_format remaining"
    class="break"
fi

# The final JSON output for Waybar
echo "{\"text\":\"$icon $time_format\", \"class\":\"$class\", \"tooltip\":\"$tooltip\"}"
exit 0
