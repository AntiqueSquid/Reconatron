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

################			 #####################
################ USEFUL CODE STARTS HERE #####################
################			 #####################

#####################################
# Function for Infrastructure Scan 
#####################################

infrastructure_scan() {
    local TARGET_INPUT=$1

    echo -e "\e[34mBeginning Infrastructure Assessment...\e[0m"

    # Check if target input exists
    if [ -z "$TARGET_INPUT" ]; then
        echo "No target provided. Please provide a target (URL/IP or file):"
        read -r TARGET_INPUT
    fi

    # Determine if the input is a file or a single target
    if [ -f "$TARGET_INPUT" ]; then
        TARGET_FILE=$TARGET_INPUT
        IS_FILE=true
        echo -e "\e[35mTarget file detected: $TARGET_FILE\e[0m"
    else
        TARGET=$TARGET_INPUT
        IS_FILE=false
        echo -e "\e[35mSingle target detected: $TARGET\e[0m"
    fi

    # Create directories for output if they don't exist
    mkdir -p nmap testssl

    # Function to run scans on a single target
    run_scans_single() {
        local target=$1
        echo "Running scans on single target: $target"

        # Run all-port scan with nmap
        echo "Running nmap all-port scan on $target..."
        nmap -p0- --min-rate 2000 --max-retries 8 "$target" --stats-every 60 --reason -Pn -oA "nmap/all-port-nmap-output-$target"

        # Run top 1000 UDP ports scan with nmap
        echo "Running nmap UDP top-1000 ports scan on $target..."
        nmap -sU --top-ports 1000 -Pn "$target" --stats-every 60 --reason -oA "nmap/UDP-top-1000-nmap-output-$target"

        # Run testssl scan for SSL/TLS testing
        echo "Running testssl on $target..."
        testssl --htmlfile "testssl/testssl-output-$target.html" --jsonfile "testssl/testssl-output-$target.json" "$target"
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

        # Run testssl on each target in the file
        while read -r target; do
            if [ -n "$target" ]; then
                echo "Running testssl on $target..."
                testssl --htmlfile "testssl/testssl-output-$target.html" --jsonfile "testssl/testssl-output-$target.json" "$target"
            fi
        done < "$target_file"
    }

    # Run the appropriate scan based on the input type
    if $IS_FILE; then
        run_scans_file "$TARGET_FILE"
    else
        run_scans_single "$TARGET"
    fi

    echo "Scanning completed. Check the 'nmap' and 'testssl' folders for results."
}



#####################################
# Function for Web Application Assessment
#####################################

web_application_assessment() {
    echo -e "\e[34mBeginning Web Application Assessment...\e[0m"

    # Check if target is provided
    if [ -z "$1" ]; then
        echo "No target provided. Please provide a target (URL/IP or file):"
        read -r TARGET_INPUT
    else
        TARGET_INPUT=$1
    fi

    # Determine if the input is a file or a single target
    if [ -f "$TARGET_INPUT" ]; then
        TARGET_FILE=$TARGET_INPUT
        IS_FILE=true
    else
        TARGET=$TARGET_INPUT
        IS_FILE=false
    fi

    # Create directories for output if they don't exist
    mkdir -p nmap testssl curl_results clickjacking nikto nuclei

    # Function to create a clickjacking test HTML file
    create_clickjacking_file() {
        local target=$1
        local filename="clickjacking/clickjacking-$target.html"
        echo -e "\e[1;34mCreating clickjacking test file for $target at $filename\e[0m"
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

    # Function to run Nuclei scans
    run_nuclei_scan() {
        local target=$1
        echo -e "\e[1;35mRunning Nuclei scan on $target...\e[0m"
        nuclei -u "$target" -o "nuclei/nuclei-output-$target.txt"
    }

    # Function to run scans on a single target
    run_scans_single() {
        local target=$1
        echo -e "\e[1;32mRunning scans on single target: $target\e[0m"

        echo -e "\e[1;34mRunning nmap all-port scan on $target...\e[0m"
        nmap -p0- --min-rate 2000 --max-retries 8 "$target" --stats-every 60 --reason -Pn -oA "nmap/TCP-all-port-nmap-output-$target"
        
        echo "Running nmap top-100-UDP-port scan on $target..."
        nmap -sU --top-ports 100 -Pn $target --stats-every 60 --reason -Pn -oA "nmap/UDP-top-100-nmap-output.txt"
        
        echo -e "\e[1;34mRunning testssl on $target...\e[0m"
        testssl --htmlfile "testssl/testssl-output-$target.html" --jsonfile "testssl/testssl-output-$target.json" "$target"

        echo -e "\e[1;34mRunning curl HEAD request on $target...\e[0m"
        curl -ik -L "$target" --head > "curl_results/curl-head-$target.txt"

        echo -e "\e[1;34mRunning Nikto scan on $target...\e[0m"
        nikto --url "$target" -output "nikto/nikto-output-$target.txt"

        create_clickjacking_file "$target"
        
        run_nuclei_scan "$target"
    }

    # Function to run scans on multiple targets from a file
    run_scans_file() {
        local target_file=$1
        echo -e "\e[1;32mRunning scans on multiple targets from file: $target_file\e[0m"

        echo "Running nmap all-TCP-port scan on all targets in $target_file..."
        nmap -p0- --min-rate 2000 --max-retries 8 -iL "$target_file" --stats-every 60 --reason -Pn -oA "nmap/TCP-all-port-nmap-output-multiple"
        
        echo "Running nmap top-100-UDP-port scan on all targets in $target_file..."
        nmap -sU --top-ports 100 -Pn -iL "$target_file" --stats-every 60 --reason -Pn -oA "nmap/UDP-top-100-nmap-output.txt"

        while read -r target; do
            if [ -n "$target" ]; then
                echo "Running testssl on $target..."
                testssl --htmlfile "testssl/testssl-output-$target.html" --jsonfile "testssl/testssl-output-$target.json" "$target"

                echo -e "\e[1;34mRunning curl HEAD request on $target...\e[0m"
                curl -ik -L "$target" --head > "curl_results/curl-head-$target.txt"

                create_clickjacking_file "$target"

                run_nuclei_scan "$target"
            fi
        done < "$target_file"
    }

    # Run scans based on input type
    if $IS_FILE; then
        run_scans_file "$TARGET_FILE"
    else
        run_scans_single "$TARGET"
    fi

    echo "Scanning completed. Check the 'nmap', 'testssl', 'curl_results', 'nikto', 'nuclei', and 'clickjacking' folders for results."
    echo "Please check the findings carefully; Autoreconatron is not a replacement for testing. Do your job properly..."
}

# Main menu
# Ensure the script is called with the correct arguments
if [ $# -lt 1 ]; then
    echo -e "\e[31mError: No target provided.\e[0m"
    echo "Usage: Reconatron.sh <IP/File>"
    exit 1
fi

# Parse the input argument
INPUT=$1

echo ""
echo -e "\e[1mPlease select the type of scan to perform:\e[0m"
echo "1) Infrastructure Scan"
echo "2) Web Application Assessment"
echo ""
echo "Enter your choice: "
read -r choice

case $choice in
    1)
        infrastructure_scan "$INPUT"
        ;;
    2)
        web_application_assessment "$INPUT"
        ;;
    *)
        echo "Invalid choice. Exiting. :("
        exit 1
        ;;
esac
