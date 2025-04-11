#!/bin/bash

# Temp file for recorded audio
AUDIO_FILE="/tmp/dictation.wav"

# Record 5 seconds of audio
arecord -f cd -d 5 -q "$AUDIO_FILE"

# Transcribe using whisper.cpp and your chosen model
TEXT=$(whisper --model /usr/share/whisper/ggml-base.en-q5_1.bin -f "$AUDIO_FILE" --output-text - | tail -n 1)

# Type the text into the focused window
xdotool type --delay 50 "$TEXT"
