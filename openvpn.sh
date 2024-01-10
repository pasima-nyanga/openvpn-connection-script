# Ensure the script is running under Bash
if [ -z "$BASH_VERSION" ]; then
  echo "Please run this script with Bash."
  exit 1
fi

# Validate that the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  exit 2
fi

# Obtain the OpenVPN configuration path from the first argument
CONFIG_PATH="$1"

# Validate that a path has been provided
if [ -z "$CONFIG_PATH" ]; then
  echo "Please provide the path to the OpenVPN configuration file."
  exit 3
fi

# Check if OpenVPN is installed and install if it isn't
if ! command -v openvpn &> /dev/null; then
  echo "OpenVPN is not installed. Installing it now."
  apt-get update
  apt-get install -y openvpn
  if ! command -v openvpn &> /dev/null; then
    echo "Failed to install OpenVPN."
    exit 4
  fi
fi

# Verify that the OpenVPN configuration file exists
if [ ! -f "$CONFIG_PATH" ]; then
  echo "OpenVPN configuration file does not exist at $CONFIG_PATH."
  exit 5
fi

# Start the OpenVPN connection
echo "Connecting to the VPN..."
openvpn --config "$CONFIG_PATH" --daemon

# Wait a bit to confirm connection
sleep 5

# Validate if the VPN connection was successful
if pgrep -x "openvpn" > /dev/null; then
  echo "Successfully connected to the VPN."
  echo "To disconnect, press Ctrl+C in this terminal or find the process id with 'pgrep openvpn' and kill it with 'sudo kill <PID>'."
else
  echo "Failed to connect to the VPN."
  exit 6
fi


# Setup a trap to handle disconnects (CTRL+C)
trap 'echo "Disconnecting from VPN."; pkill -x "openvpn"; exit 0' INT

# Keep the script running to maintain the VPN connection
while true; do
  sleep 1
done
