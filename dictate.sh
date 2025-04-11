#!/bin/bash

AUDIO_FILE="/tmp/dictation.wav"

# Record 5 seconds of audio
arecord -f cd -d 5 -q "$AUDIO_FILE"

# Transcribe using whisper.cpp
TEXT=$(whisper --model /usr/share/whisper/ggml-base.en-q5_1.bin -f "$AUDIO_FILE" --output-text - | tail -n 1)

# Clean whitespace
CLEAN_TEXT=$(echo "$TEXT" | xargs)

# Type into focused window
echo "$CLEAN_TEXT" | wtype
