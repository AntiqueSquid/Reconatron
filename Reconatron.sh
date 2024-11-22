#!/bin/bash

#################################
######### SUDO CHECKER ##########
#################################

# Check if the script is run as root (UID 0)
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo."
  exit 1
fi

#################################



################			 #####################
################ USEFUL CODE STARTS HERE #####################
################			 #####################

#####################################
# Function for Infrastructure Scan 
#####################################

infrastructure_scan() {
    local target_input=$1  # Corrected to target_input

    # Check if target input exists
    if [ -z "$target_input" ]; then
        echo "No target provided. Please provide a target (URL/IP or file):"
        read -r target_input
    fi

    # Determine if the input is a file or a single target
    if [ -f "$target_input" ]; then
        target_file=$target_input
        IS_FILE=true
        echo -e "\e[35mTarget file detected: $target_file\e[0m"
    else
        target=$target_input
        IS_FILE=false
        echo -e "\e[35mSingle target detected: $target\e[0m"
    fi

    # Create directories for output if they don't exist
    mkdir -p infrastructureTest
    mkdir -p infrastructureTest/nmap infrastructureTest/testssl



    # Function to run scans on a single target
    run_scans_single() {
        local target=$1
        echo "Running scans on single target: $target"
	echo ""

################### NMAP INFRASTRUCTURE ######################

########################################
####### NMAP TCP SINGLE IP/URL #########
########################################
	
	
	# Step 1: Run all-port scan with nmap
	echo -e "\e[34mRunning nmap all-port scan on $target...\e[0m"
	nmap -p0- --min-rate 2000 --max-retries 8 "$target" --stats-every 60 --reason -Pn -o "infrastructureTest/nmap/all-TCP-port-nmap-output-$target.txt"

	# Step 2: Extract open ports and save them to openPorts.txt
	grep "open" infrastructureTest/nmap/all-TCP-port-nmap-output-"$target".txt | awk '{print $1}' | sed 's#/tcp##' | paste -sd ',' - | tr -d '\n' > infrastructureTest/nmap/openPorts.txt

	# Step 3: Check if openPorts.txt is empty
	if [[ ! -s infrastructureTest/nmap/openPorts.txt ]]; then
    		echo -e "\e[1;33mNo open ports found. Skipping aggressive TCP scan.\e[0m"
	else
    		echo ""
    		# Display the extracted open ports
    		echo -e "\e[1;32mOpen ports extracted: $(cat infrastructureTest/nmap/openPorts.txt)\e[0m"

    		# Step 4: Ask the user if they want to continue with the more aggressive scan
    		echo ""
    		echo -e "\e[1;31mDo you want to continue with a more aggressive TCP scan (Y/N)?\e[0m"
    		read -r answer

    		# Step 5: Based on user input, run the aggressive scan(s) if the answer is 'Y'
    		if [[ "$answer" =~ ^[Yy]$ ]]; then
        		echo -e "\e[1;33mStarting more aggressive scan...\e[0m"
       			nmap -p "$(cat infrastructureTest/nmap/openPorts.txt)" -sCV "$target" -o "infrastructureTest/nmap/openPorts-TCP-Aggressive-Scan.txt"
    		else
       			echo ""
        		echo -e "\e[1;35mTCP Scan completed. No further action will be taken.\e[0m"
    		fi
	fi


########################################
####### NMAP UDP SINGLE IP/URL #########
########################################

        # Run top 1000 UDP ports scan with nmap
        echo "Running nmap UDP top-1000 ports scan on $target..."
        nmap -sU --top-ports 1000 -Pn "$target" --stats-every 60 --reason -o "infrastructureTest/nmap/UDP-top-1000-nmap-output-$target.txt"
        
	# Step 2: Extract open ports and save them to openPorts.txt
	grep "open" infrastructureTest/nmap/UDP-top-1000-nmap-output-"$target".txt | awk '{print $1}' | sed 's#/tcp##' | paste -sd ',' - | tr -d '\n' > infrastructureTest/nmap/openPortsUDP.txt

	# Step 3: Check if openPorts.txt is empty
	if [[ ! -s infrastructureTest/nmap/openPortsUDP.txt ]]; then
    		echo -e "\e[1;33mNo open ports found. Skipping aggressive TCP scan.\e[0m"
	else
    		echo ""
    		# Display the extracted open ports
    		echo -e "\e[1;32mOpen ports extracted: $(cat infrastructureTest/nmap/openPortsUDP.txt)\e[0m"

    		# Step 4: Ask the user if they want to continue with the more aggressive scan
    		echo ""
    		echo -e "\e[1;31mDo you want to continue with a more aggressive UDP scan (Y/N)?\e[0m"
    		read -r answer

    		# Step 5: Based on user input, run the aggressive scan(s) if the answer is 'Y'
    		if [[ "$answer" =~ ^[Yy]$ ]]; then
        		echo -e "\e[1;33mStarting more aggressive scan...\e[0m"
       			nmap -p "$(cat infrastructureTest/nmap/openPorts.txt)" -sCV "$target" -o "infrastructureTest/nmap/openPorts-UDP-Aggressive-Scan.txt"
    		else
       			echo ""
        		echo -e "\e[1;35mUDP Scan completed. No further action will be taken.\e[0m"
    		fi
	fi
	echo -e "\e[1;34mAll nmap scans complete.\e[0m"
	echo ""
        
########################################
######## TESTSSL SINGLE IP/URL #########
########################################     
      

        # Run testssl scan for SSL/TLS testing
        echo "Running testssl on $target..."
        testssl --htmlfile "infrastructureTest/testssl/testssl-output-$target.html" --jsonfile "infrastructureTest/testssl/testssl-output-$target.json" "$target"
    }

###################
################### NMAP  - INFRASTRUCTURE - MULTI ####################


    ########################################
    ##### NMAP TCP MULTIPLE IPs/URLs #######
    ########################################

    # Function to run scans on multiple targets from a file
    run_scans_file() {
    local target_file=$1
    echo "Running scans on targets from file: $target_file"

    # Ensure the directory for results exists
    mkdir -p nmap testssl

    # Initialize batch mode variables
    local batch_mode_enabled=false
    local batch_response=""
    local udp_batch_mode_enabled=false

    # Iterate through each target in the file
    while read -r target; do
        if [ -n "$target" ]; then
            echo -e "\e[34mRunning nmap all-port scan on $target...\e[0m"
            nmap -p0- --min-rate 2000 --max-retries 8 "$target" --stats-every 60 --reason -Pn -o "infrastructureTest/nmap/all-TCP-port-nmap-output-$target.txt"

            # Extract open ports and save them to openPorts.txt
            grep "open" "infrastructureTest/nmap/all-TCP-port-nmap-output-$target.txt" | awk '{print $1}' | sed 's#/tcp##' | paste -sd ',' - > "infrastructureTest/nmap/openPorts-$target.txt"

            # Display results
            if [[ -s "infrastructureTest/nmap/openPorts-$target.txt" ]]; then
                echo -e "\e[1;32mOpen Ports for $target: $(cat "infrastructureTest/nmap/openPorts-$target.txt")\e[0m"

                               # Check if batch mode is enabled (ask for batch mode only once)
                if ! $batch_mode_enabled; then
                    # Ask if an aggressive scan should be performed for this target
                    while true; do
                        echo -e "\e[1;31mWould you like to run an aggressive scan on the open ports (Y/N)?\e[0m"
                        read -r answer < /dev/tty
                        if [[ "$answer" =~ ^[Yy]$ ]]; then
                            aggressive_scan="Y"
                            break
                        elif [[ "$answer" =~ ^[Nn]$ ]]; then
                            aggressive_scan="N"
                            break
                        else
                            echo "Invalid response. Please enter Y or N."
                        fi
                    done

                    # Ask if the user's choice should be applied to all subsequent targets
                    while true; do
                        echo -e "\e[1;31mAutomatically apply this choice to ALL IPs/URLs (Y/N)?\e[0m"
                        read -r batch_answer < /dev/tty
                        case "$batch_answer" in
                            [Yy]*)
                                batch_mode_enabled=true
                                batch_response="$aggressive_scan"  # Use the current choice for batch mode
                                break
                                ;;
                            [Nn]*)
                                batch_mode_enabled=false  # Continue prompting for each target
                                break
                                ;;
                            *)
                                echo "Invalid response. Please enter Yes or No."
                                ;;
                        esac
                    done
                fi

                # Apply the batch response if batch mode is enabled
                if $batch_mode_enabled; then
                    answer=$batch_response
                fi

                # Execute aggressive scan if the user agreed
                if [[ "$answer" =~ ^[Yy]$ ]]; then
                    echo -e "\e[1;33mRunning aggressive scan on $target...\e[0m"
                    nmap -p "$(cat infrastructureTest/nmap/openPorts-$target.txt)" -sCV "$target" -o "infrastructureTest/nmap/openPorts-TCP-Aggressive-Scan-$target.txt"
                elif [[ "$answer" =~ ^[Nn]$ ]]; then
                    echo -e "\e[1;35mSkipping aggressive scan for $target.\e[0m"
                fi
            else
                echo -e "\e[1;33mNo open ports found for $target. Skipping aggressive scan.\e[0m"
            fi

            echo -e "\e[1;33mTCP Nmap scans Complete. Now conducting UDP Scans.\e[0m"

            ########################################
            ##### NMAP UDP MULTIPLE IPs/URLs #######
            ########################################

            # Run the UDP scan
            echo -e "\e[34mRunning nmap UDP top-1000 ports scan on $target...\e[0m"
            nmap -sU --top-ports 1000 -Pn "$target" --stats-every 60 --reason -o "infrastructureTest/nmap/UDP-top-1000-nmap-output-$target.txt"

            # Extract UDP open ports
            grep "open" "infrastructureTest/nmap/UDP-top-1000-nmap-output-$target.txt" | awk '{print $1}' | sed 's#/udp##' | paste -sd ',' - > "infrastructureTest/nmap/openPorts-UDP-$target.txt"

            # Display results for UDP
            if [[ -s "nmap/openPorts-UDP-$target.txt" ]]; then
                echo -e "\e[1;32mOpen UDP Ports for $target: $(cat "infrastructureTest/nmap/openPorts-UDP-$target.txt")\e[0m"

                # Prompt about UDP batch mode if it's the first target
                if ! $udp_batch_mode_enabled; then
                    echo -e "\e[1;31mWould you like to run an aggressive UDP scan on the open ports (Y/N)?\e[0m"
                    read -r answer

                    # Ask for UDP batch mode immediately after the first response
                    echo -e "\e[1;31mAutomatically apply this choice to ALL UDP scans (Y/N)?\e[0m"
                    read -r batch_answer

                    # Handle responses for UDP batch mode
                    if [[ "$batch_answer" =~ ^[Yy]$ ]]; then
                        udp_batch_mode_enabled=true
                        udp_batch_response="$answer"
                    fi
                fi

                # Apply the decision (either individual or batch response) for UDP
                if $udp_batch_mode_enabled; then
                    answer=$udp_batch_response
                fi

                # Execute aggressive UDP scan if the user agreed
                if [[ "$answer" =~ ^[Yy]$ ]]; then
                    echo -e "\e[1;33mRunning aggressive UDP scan on $target...\e[0m"
                    nmap -p "$(cat infrastructureTest/nmap/openPorts-UDP-"$target".txt)" -sCV "$target" -o "infrastructureTest/nmap/openPorts-UDP-Aggressive-Scan-$target.txt"
                else
                    echo -e "\e[1;35mSkipping aggressive UDP scan for $target.\e[0m"
                fi
            else
                echo -e "\e[1;33mNo open UDP ports found for $target. Skipping aggressive UDP scan.\e[0m"
            fi

            # Run testssl on the target
            echo "Running testssl on $target..."
            testssl --htmlfile "infrastructureTest/testssl/testssl-output-$target.html" --jsonfile "infrastructureTest/testssl/testssl-output-$target.json" "$target"
        fi
    done < "$target_file"  # Close the while loop
 }

    ########## Run the appropriate scan based on the input type ###########
    if $IS_FILE; then
        run_scans_file "$target_file"
    else
        run_scans_single "$target"
    fi

 echo "Scanning completed. Check the 'infrastructureTest' folder for results."
}





#####################################
# Function for Web Application Assessment
#####################################

web_application_assessment() {
    echo -e "\e[34mBeginning Web Application Assessment...\e[0m"

    # Check if target is provided
    if [ -z "$1" ]; then
        echo "No target provided. Please provide a target (URL/IP or file):"
        read -r target_input
    else
        target_input=$1
    fi

    # Determine if the input is a file or a single target
    if [ -f "$target_input" ]; then
        target_file=$target_input
        IS_FILE=true
    else
        target=$target_input
        IS_FILE=false
    fi

    # Create directories for output if they don't exist
    mkdir -p webappTest && cd webappTest
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
        echo ""
        echo -e "\e[1;35mRunning Nuclei scan on $target...\e[0m"
        echo ""
        nuclei -u "$target" -o "nuclei/nuclei-output-$target.txt"
    }

    # Function to run scans on a single target
    run_scans_single() {
        local target=$1
        echo ""
        echo -e "\e[1;32mRunning scans on single target: $target\e[0m"

        echo -e "\e[1;34mRunning nmap all-port scan on $target...\e[0m"
        nmap -p0- --min-rate 2000 --max-retries 8 "$target" --stats-every 60 --reason -Pn -oA "nmap/TCP-all-port-nmap-output-$target"
        
        echo "Running nmap top-100-UDP-port scan on $target..."
        nmap -sU --top-ports 100 -Pn "$target" --stats-every 60 --reason -Pn -oA "nmap/UDP-top-100-nmap-output.txt"
        
        echo -e "\e[1;34mRunning testssl on $target...\e[0m"
        testssl --htmlfile "testssl/testssl-output-$target.html" --jsonfile "testssl/testssl-output-$target.json" "$target"

        echo -e "\e[1;34mRunning curl headers request on $target...\e[0m"
        curl -ik -L "$target" --head > "curl_results/curl-headers-$target.txt"
        
        echo -e "\e[1;34mRunning curl TRACE request on $target...\e[0m"
        curl -ik -L "$target" -X TRACE --head > "curl_results/curl-TRACE-$target.txt"
        
        echo -e "\e[1;34mRunning curl PUT request on $target...\e[0m"
        curl -ik -L "$target" -X PUT --head > "curl_results/curl-PUT-$target.txt"

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
                
                echo -e "\e[1;34mRunning curl TRACE request on $target...\e[0m"
        	curl -ik -L "$target" -X TRACE --head > "curl_results/curl-TRACE-$target.txt"
        
       		echo -e "\e[1;34mRunning curl PUT request on $target...\e[0m"
        	curl -ik -L "$target" -X PUT --head > "curl_results/curl-PUT-$target.txt"

                create_clickjacking_file "$target"

                run_nuclei_scan "$target"
            fi
        done < "$target_file"
    }

    # Run scans based on input type
    if $IS_FILE; then
        run_scans_file "$target_file"
    else
        run_scans_single "$target"
    fi

    echo "Scanning completed. Check the 'webappTest' folder for results."
    echo "Please check the findings carefully; Autoreconatron is not a replacement for testing. Do your job properly..."
}

#########################################################
#########################################################
#########################################################

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


#########################################################
#########################################################
#########################################################


# Main menu
# Ensure the script is called with the correct arguments
if [ $# -lt 1 ]; then
    echo -e "\e[31mError: No target provided.\e[0m"
    echo "Usage: Reconatron.sh <IP/File>"
    exit 1
fi

# Parse the input argument
INPUT=$1

# Call the random ASCII art function
random_ascii_art

echo ""
echo "=================================================================================="
echo -e "\e[1mPlease select the type of scan to perform:\e[0m"
echo "1) Infrastructure Scan (Aggressive scans for single IPs & multi-IPs experimental)"
echo "2) Web Application Assessment (Work In Progress, some functionality)"
echo ""
echo "=================================================================================="
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

