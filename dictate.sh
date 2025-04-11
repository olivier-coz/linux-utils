#!/bin/bash

# Record audio
AUDIO_FILE="/tmp/dictation.wav"
arecord -f cd -d 5 -q "$AUDIO_FILE"

# Transcribe it
TEXT=$(whisper --model /usr/share/whisper/ggml-base.en-q5_1.bin -f "$AUDIO_FILE" --output-text - | tail -n 1)

# Type it with wtype (Wayland-safe "xdotool")
wtype "$TEXT"
