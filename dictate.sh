#!/bin/bash

AUDIO_FILE="/tmp/dictation.wav"
LOCK_FILE="/tmp/dictation-recording.lock"
MODEL_PATH="/usr/share/whisper.cpp-model-base.en-q5_1/ggml-base.en-q5_1.bin"
TIMER_PID_FILE="/tmp/dictation-timeout.pid"

# Function to stop recording and transcribe
stop_recording() {
    echo "Stopping recording..."
    kill -INT "$(cat $LOCK_FILE)" 2>/dev/null
    rm -f "$LOCK_FILE"
    rm -f "$TIMER_PID_FILE"

    sleep 0.3  # Give parecord time to flush

    echo "Transcribing..."
    TEXT=$(/usr/bin/whisper-cli -m "$MODEL_PATH" "$AUDIO_FILE" | grep '^\[' | grep -oP '\] *\K.+' | xargs)
    CLEAN_TEXT=$(echo "$TEXT" | xargs)
    echo "Transcribed Text: $CLEAN_TEXT"
    echo "$TEXT" | wl-copy
    canberra-gtk-play -i complete &
}


# Check if recording is in progress
if [ -f "$LOCK_FILE" ]; then
    stop_recording
else
    echo "Starting recording..."
    rm -f "$AUDIO_FILE"

    # Start parecord and store PID
    parecord --channels=1 --rate=16000 --format=s16le "$AUDIO_FILE" &
    echo $! > "$LOCK_FILE"

    # Start timeout watchdog (2 minutes = 120 seconds)
    (
        sleep 120
        if [ -f "$LOCK_FILE" ]; then
            echo "Auto-stopping after 2 minutes..."
            "$0"
        fi
    ) &
    echo $! > "$TIMER_PID_FILE"
fi

