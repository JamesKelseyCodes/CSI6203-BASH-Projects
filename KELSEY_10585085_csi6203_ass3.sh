#!/bin/bash
#name: JAMES KELSEY  student number: 10585085

#this function initializes variables that are used throughout the script, and resets them whenever a new search operation is performed
resetVariables() {
    suspiciousFlag="suspicious"; column=0; var=0; awkOperatorSymbol="~"; totals=0; flowRestart=1; fieldName="null";
}

#number input is validated here, it will loop until at least one digit is entered
validateNumber() {
    read -p "Enter a $fieldName number: " var

    until [[ $var =~ ^[[:digit:]]+$ ]]; do
        read -p "Invalid $fieldName input - please try again: " var
    done
}

#this function generates a log file menu using an array and for loop.
logSelection() {
    logFiles=( $(find -maxdepth 1 -name 'serv_acc_log*' | cut -c 3-) "ALL_LOG_FILES" ) #piping and cut command is used to 'clean up' the text that is passed to the array
    echo -e "$((${#logFiles[@]}-1)) log files found in current directory:\n"

    local mennum=1
    for log in ${logFiles[@]}; do
        echo "$mennum)   $log"
        ((mennum++))
    done
    #ADVANCED FUNCTIONAL REQUIREMENT 1: user can select search ALL available log files. the script will use the pattern "serv_acc_log_*.csv" - the asterisk being a wildcard.
    echo -e "\nSelect the file you want to search, i.e. [1-$((${#logFiles[@]}-1))], or [$((${#logFiles[@]}))] to search all log files.\n"
    fieldName="menu number"

    until [[ $var -ge 1 ]] && [[ $var -le ${#logFiles[@]} ]]; do
        validateNumber
        logFileDisplay="${logFiles[$(($var-1))]}"
        [[ var -eq ${#logFiles[@]} ]] && logFile="serv_acc_log_*.csv" || logFile="${logFiles[$(($var-1))]}"
    done
}

#a select loop is used to create a submenu when searching by protocol. the select loop is used with a conditional statement to validate user input.
protocolSelection() {
    column=3
    PS3="Which PROTOCOL do you want to search for? "
    protocolNames=("TCP" "ICMP" "UDP" "GRE")

    select protocol in "${protocolNames[@]}"; do
            [[ -n $protocol ]] && var=$protocol && break || echo "Invalid input - please try again" ; continue
    done

    var=\"$var\"
}

#this function is used when searching for source or destination IP. The user only needs to provide a partial search string.
ipSelection() {
    read -p "Enter the start of the $fieldName (partial match allowed): " var

    #the until loop ensures that the input string has a non-zero length, i.e. at least one character was entered
    until [[ -n $var ]]; do
        read -p "Invalid input - please try again: " var
    done

    var=$( echo $var | tr '[:lower:]' '[:upper:]' ) #user input is made case-insensitive with the tr command
    var=\"^$var\" #an ^ anchor is added to the string that ensures the search matches the beginning of the string
}

#this function is small becauses it uses another function for input validation
portSelection() {
    validateNumber && awkOperatorSymbol="=="   
}

#a submenu is created. a case statement is wrapped inside a while loop to provide input validation.
packetsAndByesSelection() {
    totals=1
    echo "Search method for $fieldName:"
    echo -e "1) equal to input\n2) less than input\n3) greater than input\n4) not equal to input (inverse search)\n"

    while true; do
        read -p "Make a selection (1-4): " userSelection
        case $userSelection in
            1) awkOperatorSymbol="==";;
            2) awkOperatorSymbol='<';;
            3) awkOperatorSymbol=">";;
            4) awkOperatorSymbol="!~";;
            *) echo "not a valid option, try again" && continue #this default option serves as a 'catch-all' against invalid user input
        esac
        break
    done
    validateNumber
}

#this function is the main menu of the script. once again, a case statement is wrapped inside a while loop to form the basis of the menu and input validation.
mainMenu() {
    tput reset
    while true; do
        echo -e "Log file selected: $logFileDisplay\n"
        IFS=","
        local x=0
        local mennum=1

        #hard-coding of values is avoided - instead the column titles are taken from the log file itself, using a loop, piping and the head command. These values are used to create the main menu.
        for item in $( cat $logFile | head -1 | sed 's/ /_/g'); do
            ((x++)); [[ $x -ge 3 ]] && [[ $x -le 9 ]] || [[ $x -eq 13 ]] && echo -e "$mennum)   $item" && ((mennum++)) && field+=($item)
        done
        
        IFS=$OLDIFS
        echo -e "L)   LOAD NEW LOG FILE\nQ)   QUIT\n\nSelect a search option above i.e. [1-8], or [L] to change log file, or [Q] to quit.\n"
        read -p "Enter a menu number: " userOption
        tput reset

        case $userOption in
            1)  protocolSelection;;

            2)  fieldName="${field[1]}"
                column=4
                ipSelection;;

            3)  fieldName="${field[2]}"
                column=5
                portSelection;;

            4)  fieldName="${field[3]}"     
                column=6
                ipSelection;;

            5)  fieldName="${field[4]}"     
                column=7
                portSelection;;

            6)  fieldName="${field[5]}"
                column=8
                packetsAndByesSelection;;

            7)  fieldName="${field[6]}"
                column=9
                packetsAndByesSelection;;

            8)  suspiciousFlag="normal"
                echo "Only NORMAL class will be displayed";;

            l)  flowRestart=0 && flowControl;;

            q)  exit 0;;

            *)  echo -e "Invalid Input - Please try again\n" && continue;;
        esac
        break
    done
}

#awk scans the log files for matching patterns. there is interaction between awk and bash - the values gathered above are placed into the awk conditional statements.
#soft-coding principles are used - column titles are taken from the log file itself using the 'getline' command and saved as awk variables (c3, c4, c5...)
#ADVANCED FUNCTIONAL REQUIREMENT 2 - when packets or bytes are selected, they will be respectively tallied and displayed in the final row
awkEngine() {
fileNameValidation
tput reset
        awk ' BEGIN {FS=","; totalSum=0;
            getline; c3=$3; c4=$4; c5=$5; c6=$6; c7=$7; c8=$8; c9=$9; c13=$13;
            printf "%-14s%-14s%-14s%-14s%-14s%-14s%-14s%5s\n", c3, c4, c5, c6, c7, c8, c9, c13}
            NR>1 {
                    if ($'$column' '$awkOperatorSymbol' '$var' && $13 ~ "'$suspiciousFlag'")
                        {
                            printf "%-14s%-14s%-14s%-14s%-14s%-14s%-14s%5s\n", $3, $4, $5, $6, $7, $8, $9, $13;
                            totalSum+=$'$column';
                        }
                }
            END {
                    if ('$totals'==1) 
                        {
                            print "Total '$fieldName' for all matching rows is: " totalSum
                        }
                }
            ' $logFile > $fileName.csv && cat $fileName.csv
}

#this function asks if another search operation will be conducted. 'y' returns the script to the main menu. 'n' terminates the script.
askAgain() {
    while true; do echo
        read -p "Do you want to search again? [Y/n] " input
        tput reset
        case $input in
            y) flowRestart=1 && flowControl;;
            n) exit 0;;
            *) echo -e "Invalid input - Please try again\n" && continue;;
        esac
        break
    done
}

#the results of each search are also exported to a .csv file with a name of the user's choosing. this function ensures that the file name is valid (at least one character) and is uniquely named.
fileNameValidation() {

    read -p "Enter a file name for output: " fileName
    while [[ ! $fileName =~ [[:alnum:]] ]]; do
        read -p "Invalid input - must contain at least one alpha-numeric character. Try again: " fileName 
    done

    fileName=$(echo $fileName | sed -e 's/\\//g' -e 's|/||g' ) #piping and sed are used to remove slashes from user input (otherwise file name can be erroneously interpreted as a directory)

    #if the file name already exists, this loop appends '-new' to it. i.e. 'file.csv' will become 'file-new.csv'. The loop ensures that the results files of previous searches are not overwritten. 
    while [[ -f $fileName ]] || [[ -f "$fileName.csv" ]]; do
        fileName=$(echo $fileName | sed 's/\('$fileName'\)/\1-new/')
        local existingMessage="File of that name already exists. "
    done
    echo -e "\n"$existingMessage"Output will be saved as '$fileName.csv'" && sleep 2    
} 

#this function provides a control flow to the script, stating which order the functions should be executed
flowControl() {
    [[ $flowRestart -eq 0 ]] && logSelection
    resetVariables
    mainMenu
    awkEngine
    askAgain
}

shopt -s nocasematch #this changes the scripts shell option to 'no case match' - user input is not case sensitive, i.e. 'y' and 'Y' are functionally the same
OLDIFS=$IFS #saves the IFS setting so IFS can be returned to its original state later in the script
flowRestart=0
flowControl #calls the scripts first function
