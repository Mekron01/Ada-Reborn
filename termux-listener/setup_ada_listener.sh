#!/data/data/com.termux/files/usr/bin/bash

BASE_DIR="$HOME/ada"
SCRIPT_PATH="$BASE_DIR/termux_listener.py"
RUN_SCRIPT="$BASE_DIR/run_listener.sh"
LOG_DIR="$BASE_DIR/logs"
BASHRC="$HOME/.bashrc"

mkdir -p "$LOG_DIR"

cat > "$SCRIPT_PATH" << 'EOF'
import socket, json, subprocess
HOST = '0.0.0.0'
PORT = 5050
print(f"[+] Starting Ada Termux listener on port {PORT}")
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind((HOST, PORT))
    s.listen()
    while True:
        conn, addr = s.accept()
        with conn:
            print(f"[+] Connection from {addr}")
            data = conn.recv(1024).decode()
            if not data: continue
            try:
                payload = json.loads(data)
                command = payload.get("command", "")
                print(f"[>] Received command: {command}")
                if command == "restart_termux":
                    output = "Restarting Termux would kill the session, skipping..."
                elif command == "run_diagnostics":
                    output = subprocess.getoutput("uptime && df -h")
                else:
                    output = subprocess.getoutput(command)
                conn.sendall(output.encode())
            except Exception as e:
                conn.sendall(f"Error processing command: {e}".encode())
EOF

cat > "$RUN_SCRIPT" << EOF
#!/data/data/com.termux/files/usr/bin/bash
SCRIPT_PATH="$SCRIPT_PATH"
LOG_FILE="$LOG_DIR/ada_listener_\$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$LOG_DIR"
if [ -f "\$SCRIPT_PATH" ]; then
    echo "[+] Starting Ada listener..." | tee -a "\$LOG_FILE"
    python "\$SCRIPT_PATH" 2>&1 | tee -a "\$LOG_FILE"
else
    echo "[-] Script not found at \$SCRIPT_PATH" | tee -a "\$LOG_FILE"
fi
EOF

chmod +x "$RUN_SCRIPT"

if ! grep -q "run_listener.sh" "$BASHRC"; then
    echo -e "\n# Ada voice listener autostart" >> "$BASHRC"
    echo "if ! pgrep -f 'termux_listener.py' > /dev/null; then" >> "$BASHRC"
    echo "    nohup $RUN_SCRIPT &" >> "$BASHRC"
    echo "fi" >> "$BASHRC"
fi

echo "[✔] Setup complete. Run with:"
echo "$RUN_SCRIPT"
