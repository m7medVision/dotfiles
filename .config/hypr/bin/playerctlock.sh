#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 --title | --arturl | --artist | --length | --album | --source | --status"
    exit 1
fi

# Function to get metadata using playerctl
get_metadata() {
    key=$1
    playerctl metadata --format "{{ $key }}" 2>/dev/null
}

# Function to determine the source and return an icon and text
get_source_info() {
    trackid=$(get_metadata "mpris:trackid")
    if [[ "$trackid" == *"firefox"* ]]; then
        echo -e "Firefox 󰈹"
    elif [[ "$trackid" == *"spotify"* ]]; then
        echo -e "Spotify "
    elif [[ "$trackid" == *"chromium"* ]]; then
        echo -e "Chrome "
    elif [[ "$trackid" == *"vlc"* ]]; then
        echo -e "VLC 🎬"
    elif [[ "$trackid" == *"mpv"* ]]; then
        echo -e "MPV 📹"
    else
        echo -e "Unknown 🎵"
    fi
}

# Parse the argument
case "$1" in
--title)
    title=$(get_metadata "xesam:title")
    if [ -z "$title" ]; then
        echo "No Media Playing"
    else
        echo "${title:0:35}"
    fi
    ;;
--arturl)
    url=$(get_metadata "mpris:artUrl")
    if [ -z "$url" ]; then
        echo "/home/mohammed/.config/hypr/bin/default-music.png"
    else
        if [[ "$url" == file://* ]]; then
            url=${url#file://}
        fi
        echo "$url"
    fi
    ;;
--artist)
    artist=$(get_metadata "xesam:artist")
    if [ -z "$artist" ]; then
        echo ""
    else
        echo "${artist:0:30}"
    fi
    ;;
--length)
    length=$(get_metadata "mpris:length")
    if [ -z "$length" ]; then
        echo ""
    else
        # Convert length from microseconds to minutes:seconds format
        total_seconds=$((length / 1000000))
        minutes=$((total_seconds / 60))
        seconds=$((total_seconds % 60))
        printf "%d:%02d" $minutes $seconds
    fi
    ;;
--status)
    status=$(playerctl status 2>/dev/null)
    if [[ $status == "Playing" ]]; then
        echo "󰐊"
    elif [[ $status == "Paused" ]]; then
        echo "󰏤"
    else
        echo "󰓛"
    fi
    ;;
--album)
    album=$(get_metadata "xesam:album")
    if [[ -n $album ]]; then
        echo "${album:0:25}"
    else
        status=$(playerctl status 2>/dev/null)
        if [[ -n $status ]]; then
            echo "Single Track"
        else
            echo ""
        fi
    fi
    ;;
--source)
    get_source_info
    ;;
*)
    echo "Invalid option: $1"
    echo "Usage: $0 --title | --arturl | --artist | --length | --album | --source | --status"
    exit 1
    ;;
esac