#!/bin/sh

# Stop the script if any command fails
set -e

# Check for Ubuntu and ARM64 architecture
if [[ "$(uname -a)" != *Ubuntu* ]] || [[ "$(uname -m)" != *aarch64* ]]; then
  echo "This script is intended for Ubuntu on ARM64 architecture."
  exit 1
fi

# Check for sudo access
if [ "$(id -u)" != "0" ]; then
  echo "Please run as root or with sudo."
  exit 1
fi

# Update and install packages
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install libcurl4-openssl-dev libjansson-dev libomp-dev git screen nano jq wget

# Validate that jq is installed
if ! command -v jq &> /dev/null; then
  echo "jq is not installed. Installing now..."
  sudo apt-get install -y jq
fi

# Download and install libssl
LIBSSL_URL="http://ports.ubuntu.com/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_arm64.deb"
wget $LIBSSL_URL
sudo dpkg -i libssl1.1_1.1.0g-2ubuntu4_arm64.deb
rm libssl1.1_1.1.0g-2ubuntu4_arm64.deb

# Setup ccminer
mkdir ~/ccminer
cd ~/ccminer

# Download latest release from GitHub
GITHUB_RELEASE_JSON=$(curl --silent "https://api.github.com/repos/Oink70/Android-Mining/releases?per_page=1" | jq -c '[.[] | del (.body)]')
GITHUB_DOWNLOAD_URL=$(echo $GITHUB_RELEASE_JSON | jq -r ".[0].assets | .[] | .browser_download_url")
GITHUB_DOWNLOAD_NAME=$(echo $GITHUB_RELEASE_JSON | jq -r ".[0].assets | .[] | .name")

echo "Downloading latest release: $GITHUB_DOWNLOAD_NAME"

wget ${GITHUB_DOWNLOAD_URL} -O ~/ccminer/ccminer
wget https://raw.githubusercontent.com/TheRetroMike/VerusCliMining/main/config.json -O ~/ccminer/config.json
chmod +x ~/ccminer/ccminer

# Prompt for worker name
read -p "Enter your worker name: " worker_name
sed -i "s/DEFAULT_WORKER_NAME/$worker_name/" ~/ccminer/config.json

# Create start.sh
cat << EOF > ~/ccminer/start.sh
#!/bin/sh
~/ccminer/ccminer -c ~/ccminer/config.json
EOF
chmod +x start.sh

echo "Setup is complete."
echo "Start the miner with 'cd ~/ccminer; ./start.sh'."
