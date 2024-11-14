#!/bin/bash

# Define functions for each ASCII art

dancing_banana() {
    echo -e "\e[1;33m"
    echo "  o    "
    echo "   o   "
    echo "    o  "
    echo "  \\ | / "
    echo "   \\|/  "
    echo " '.-O-.' "
    echo " /(_|_)\ "
    echo "   | |   "
    echo "   | |   "
    echo -e "\e[0m"
    echo "The dancing banana wishes you luck!"
}

happy_robot() {
    echo -e "\e[1;34m"
    echo "         [^_^]"
    echo "        /|   |\\"
    echo "       ( |   | )"
    echo "       / || || \\"
    echo "      / / || || \\ \\"
    echo "   _ ( (_/   \\_) ) _"
    echo "  ( '------'----'------' )"
    echo "   '\\--.__.__.__.__.__//'"
    echo -e "\e[0m"
    echo "Beep boop! Scanning in progress..."
}

waving_bear() {
    echo -e "\e[1;32m"
    echo "ʕ •ᴥ•ʔﾉﾞ"
    echo "Hello from the bear! Just here for a good time."
    echo -e "\e[0m"
}

cool_cat() {
    echo -e "\e[1;36m"
    echo " /\_/\  "
    echo "( o.o )"
    echo " > ^ <"
    echo -e "\e[0m"
    echo "This cool cat is watching over your script!"
}

smiley_face() {
    echo -e "\e[1;33m"
    echo "       .-''''''-. "
    echo "     .'          '."
    echo "    /   O      O   \\"
}

# Function to display random ASCII art
random_ascii_art() {
    # Array of available art functions
    local arts=("dancing_banana" "happy_robot" "waving_bear" "cool_cat" "smiley_face")

    # Select a random function
    local random_art=${arts[$RANDOM % ${#arts[@]}]}

    # Call the selected function
    $random_art
}

# Call the random ASCII art function
random_ascii_art

#Start of ACTUALLY useful code...
echo -e "\e[34mBeginning your scans...\e[0m"


# Check for input argument
if [ -z "$1" ]; then
    echo "Usage: $0 <URL/IP or target_file>"
    exit 1
fi

# Determine if the input is a file or a single target
if [ -f "$1" ]; then
    TARGET_FILE=$1
    IS_FILE=true
else
    TARGET=$1
    IS_FILE=false
fi

# Create directories for output if they don't exist
mkdir -p nmap testssl curl_results clickjacking

# Function to create a clickjacking test HTML file
create_clickjacking_file() {
    local target=$1
    local filename="clickjacking/clickjacking-$target.html"
    echo "Creating clickjacking test file for $target at $filename"

    # Generate HTML file content
    cat << EOF > "$filename"
<html>
    <head>
        <title>Clickjacking Test Page for $target</title>
    </head>
    <body>
        <iframe src="$target" width="600" height="600"></iframe>
    </body>
</html>
EOF
}

# Function to run scans on a single target
run_scans_single() {
    local target=$1
    echo -e "\e[1;32mRunning scans on single target: $target\e[0m"

    # Run all-port scan with nmap
    echo -e "\e[34mRunning nmap all-port scan on $target...\e[0m"
    nmap -p1- --min-rate 2000 --max-retries 8 "$target" --stats-every 60 --reason -Pn -oA "nmap/all-port-nmap-output-$target"

    # Run top 1000 UDP ports scan with nmap
    echo -e "\e[34mRunning nmap UDP top-1000 ports scan on $target...\e[0m"
    nmap -sU --top-ports 1 -Pn "$target" --stats-every 60 --reason -oA "nmap/UDP-top-1000-nmap-output-$target"

    # Run testssl scan for SSL/TLS testing
    echo -e "\e[34mRunning testssl on $target...\e[0m"
    testssl --htmlfile "testssl/testssl-output-$target.html" --jsonfile "testssl/testssl-output-$target.json" "$target"

    # Run curl commands for HTTP testing
    echo "Running curl HEAD request on $target..."
    curl -ik -L "$target" --head > "curl_results/curl-head-$target.txt" && cat "curl_results/curl-head-$target.txt"

    echo "Running curl TRACE request on $target..."
    curl -ik -L "$target" -X TRACE --head > "curl_results/curl-trace-$target.txt" && cat "curl_results/curl-trace-$target.txt"

    echo "Running curl PUT request on $target..."
    curl -ik -L "$target" -X PUT --head > "curl_results/curl-put-$target.txt" && cat "curl_results-trace-$target.txt"

    # Create a clickjacking test HTML file
    create_clickjacking_file "$target"

    # Run Nikto web server scan
    echo "Running Nikto scan on $target..."
    nikto --url "$target" -output "nikto/nikto-output-$target.txt"

}

# Function to run scans on multiple targets from a file
run_scans_file() {
    local target_file=$1
    echo "Running scans on multiple targets from file: $target_file"

    # Run all-port scan with nmap
    echo "Running nmap all-port scan on all targets in $target_file..."
    nmap -p0- --min-rate 2000 --max-retries 8 -iL "$target_file" --stats-every 60 --reason -Pn -oA "nmap/all-port-nmap-output-multiple"

    # Run top 1000 UDP ports scan with nmap
    echo "Running nmap UDP top-1000 ports scan on all targets in $target_file..."
    nmap -sU --top-ports 1000 -Pn -iL "$target_file" --stats-every 60 --reason -oA "nmap/UDP-top-1000-nmap-output-multiple"

    # Run testssl and curl commands for each target in the file
    while read -r target; do
        if [ -n "$target" ]; then
            echo "Running testssl on $target..."
            testssl --htmlfile "testssl/testssl-output-$target.html" --jsonfile "testssl/testssl-output-$target.json" "$target"

                echo "Running curl HEAD request on $target..."
                curl -ik -L "$target" --head > "curl_results/curl-head-$target.txt" && cat "curl_results/curl-head-$target.txt"

                echo "Running curl TRACE request on $target..."
                curl -ik -L "$target" -X TRACE --head > "curl_results/curl-trace-$target.txt" && cat "curl_results/curl-trace-$target.txt"

                echo "Running curl PUT request on $target..."
                curl -ik -L "$target" -X PUT --head > "curl_results/curl-put-$target.txt" && cat "curl_results-trace-$target.txt"

            # Create a clickjacking test HTML file
            create_clickjacking_file "$target"
        fi
    done < "$target_file"
}

# Run the appropriate scan based on the input type
if $IS_FILE; then
    run_scans_file "$TARGET_FILE"
else
    run_scans_single "$TARGET"
fi

echo "Scanning completed. Check the 'nmap', 'testssl', 'curl_results', and 'clickjacking' folders for results."
