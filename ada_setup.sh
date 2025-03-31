#!/data/data/com.termux/files/usr/bin/bash
###############################################################################
# ada_setup.sh
# Automates environment setup for Ada-Reborn: installs Termux packages,
# clones/builds whisper.cpp & piper, downloads the whisper model,
# and creates a sample ada_main.sh script for offline STT (via whisper.cpp)
# and TTS (via piper).
#
# Prerequisites:
#  - Install "Termux:API" Android app (from F-Droid or GitHub).
#  - Grant Termux permissions (Location, Storage, Microphone) in Android settings.
###############################################################################

set -e  # Exit on error

# Define directories
REPO_DIR="$HOME/Ada-Reborn"
WHISPER_DIR="$REPO_DIR/whisper.cpp"
PIPER_DIR="$REPO_DIR/piper"
ADA_MAIN="$REPO_DIR/ada_main.sh"

echo "=== [Ada Setup] Starting... ==="
echo "Using repository directory: $REPO_DIR"

#-----------------------------------------------------------------------------
# Step 1: Install required packages
#-----------------------------------------------------------------------------
echo "[1/6] Installing required Termux packages..."
pkg update -y && pkg upgrade -y
pkg install -y git curl python cmake clang ffmpeg build-essential termux-api
pkg install -y busybox net-tools

#-----------------------------------------------------------------------------
# Step 2: Prepare folder structure
#-----------------------------------------------------------------------------
echo "[2/6] Creating folder structure..."
mkdir -p "$REPO_DIR"
# Whisper.cpp and piper will be cloned into their own subfolders.
# (The directories will be created automatically by git clone.)

#-----------------------------------------------------------------------------
# Step 3: Clone and build whisper.cpp
#-----------------------------------------------------------------------------
echo "[3/6] Cloning & building whisper.cpp..."
if [ ! -d "$WHISPER_DIR/.git" ]; then
  git clone --depth=1 https://github.com/ggerganov/whisper.cpp.git "$WHISPER_DIR"
else
  cd "$WHISPER_DIR" && git pull || echo "whisper.cpp pull failed, continuing..."
fi

cd "$WHISPER_DIR"
# Download the base.en model using the updated script at the repo root
echo "Downloading base.en model using download-ggml-model.sh..."
bash ./download-ggml-model.sh base.en

# Build whisper.cpp
mkdir -p build && cd build
cmake ..
make

#-----------------------------------------------------------------------------
# Step 4: Clone and build piper
#-----------------------------------------------------------------------------
echo "[4/6] Cloning & building piper..."
if [ ! -d "$PIPER_DIR/.git" ]; then
  git clone --depth=1 https://github.com/rhasspy/piper.git "$PIPER_DIR"
else
  cd "$PIPER_DIR" && git pull || echo "piper pull failed, continuing..."
fi

cd "$PIPER_DIR"
# Build piper
mkdir -p build && cd build
cmake ..
make

# Download an example English voice model if not already present
PIPER_MODEL_DIR="$PIPER_DIR/models"
mkdir -p "$PIPER_MODEL_DIR"
if [ ! -f "$PIPER_MODEL_DIR/en-us-amy-low.onnx" ]; then
  echo "Downloading example piper voice (en-us-amy-low.onnx)..."
  curl -L -o "$PIPER_MODEL_DIR/en-us-amy-low.onnx" \
    https://github.com/rhasspy/piper/releases/download/v0.0.2/en-us-amy-low.onnx
fi

#-----------------------------------------------------------------------------
# Step 5: Create a sample main script (ada_main.sh)
#-----------------------------------------------------------------------------
echo "[5/6] Creating sample ada_main.sh script..."
cat << 'EOF' > "$ADA_MAIN"
#!/data/data/com.termux/files/usr/bin/bash
###############################################################################
# ada_main.sh
# A sample script that:
#   1. Records 5 seconds of audio from the microphone.
#   2. Transcribes it using whisper.cpp.
#   3. Uses the transcription as a response (echoed back).
#   4. Speaks the response using piper.
#
# Ensure that Termux:API is installed and required permissions (mic, storage,
# location) are granted in Android settings.
###############################################################################

REPO_DIR="$HOME/Ada-Reborn"
WHISPER_DIR="$REPO_DIR/whisper.cpp"
PIPER_DIR="$REPO_DIR/piper"
WHISPER_BUILD="$WHISPER_DIR/build"
PIPER_BUILD="$PIPER_DIR/build"
WHISPER_MODEL="$WHISPER_DIR/models/ggml-base.en.bin"
PIPER_MODEL="$PIPER_DIR/models/en-us-amy-low.onnx"

# Temporary file paths
AUDIO_RAW="/tmp/ada_recording.wav"
AUDIO_TXT="/tmp/ada_transcript.txt"

# 1. Record audio (5 seconds) - you must grant microphone permission.
echo "Recording 5 seconds of audio..."
termux-microphone-record start -f "$AUDIO_RAW"
sleep 5
termux-microphone-record stop

# 2. Transcribe audio with whisper.cpp
echo "Transcribing audio..."
$WHISPER_BUILD/main -m "$WHISPER_MODEL" -f "$AUDIO_RAW" --language en --output-txt -of /tmp/ada_result --threads 4 --beam_size 1
mv /tmp/ada_result.txt "$AUDIO_TXT" 2>/dev/null || echo "Transcription file not found."

# 3. Read transcript and prepare response
TRANSCRIPT="$(cat "$AUDIO_TXT" 2>/dev/null || echo "(no input)")"
echo "Heard: '$TRANSCRIPT'"
RESPONSE="You said: $TRANSCRIPT"

# 4. Speak response with piper
echo "Speaking response..."
echo "$RESPONSE" | $PIPER_BUILD/piper --model "$PIPER_MODEL"

# Cleanup temporary files
rm -f "$AUDIO_RAW" "$AUDIO_TXT"
EOF

chmod +x "$ADA_MAIN"

#-----------------------------------------------------------------------------
# Step 6: Final instructions
#-----------------------------------------------------------------------------
echo "[6/6] Setup complete!"
echo ""
echo "=== NEXT STEPS ==="
echo "1. Manually install the Termux:API Android app (from F-Droid or GitHub) if not already installed."
echo "2. Grant Termux required permissions in Android settings: Location, Storage, and Microphone."
echo "3. To test, run the main Ada script:"
echo "      cd $REPO_DIR"
echo "      ./ada_main.sh"
echo ""
echo "The script will record audio, transcribe it with whisper.cpp, and speak a response using piper."
echo ""
echo "For further enhancements, consider integrating wake-word detection and a local LLM for advanced responses."
echo "Happy hacking!"
echo "=== [Ada Setup] All done! ==="
