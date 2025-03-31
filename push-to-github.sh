#!/data/data/com.termux/files/usr/bin/bash

# Push Ada files to GitHub repo "Ada-Reborn"

# Configure Git identity
git config --global user.name "Mekron01"
git config --global user.email "mekron01@users.noreply.github.com"
git config --global credential.helper store

# Store GitHub token
mkdir -p ~/.config/git
cat <<EOF > ~/.git-credentials
https://Mekron01:8nwJbwXPpyaq7JP@github.com
EOF

# Clone the repo if it doesn't exist
cd ~
if [ ! -d "Ada-Reborn" ]; then
    git clone https://github.com/Mekron01/Ada-Reborn.git
fi

cd Ada-Reborn

# Copy Ada files into the repo
cp ~/ada-mobile-setup.sh .
cp ~/ada_mic_test.py .

# Add, commit, and push
git add ada-mobile-setup.sh ada_mic_test.py
git commit -m "Add Ada mobile setup script and voice test"
git push
