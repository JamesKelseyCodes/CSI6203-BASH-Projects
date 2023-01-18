#!/bin/bash
#name: JAMES KELSEY  student number: 10585085

#declares the array which will be used throughout the script
declare -a primeArray

#validates the user input for lower bound, rejecting any strings, nulls, floats etc.
while true; do
    read -p "Range start: " lowerBound
    [[ $lowerBound =~ ^[[:digit:]]+$ ]] && [[ $lowerBound -ge 2 ]] && break || echo "Invalid start range value. Start range must be an integer greater than 1. Please try again"
done

#validates the user input for upper bound, also ensures there is at least one number between lower and upper range bound provided.
while true; do
    read -p "Range end: " upperBound
    [[ $upperBound =~ ^[[:digit:]]+$ ]] && [[ $upperBound -gt $(($lowerBound+1)) ]] && break || echo "Invalid end range value. Start range must be an integer and at least 2 digits greater than the start range. Please try again."
done    

#creates new variables from existing values. The new variables will be modified below, while the original user-input values will be retained for use later in the script.
x=$lowerBound
y=$upperBound

#finds all prime numbers between user-provided range. uses nested loops to achieve this.
for (($x; $x < $y; x++)) 
do
    for ((i=2; i < $x; i++)) 
    do
            [[ $(($x%i)) -eq 0 ]] && break
    done
    [[ $i -eq $x ]] && primeArray+=("[$x]")
done

#calculates sum of the prime numbers, while also removing unneccesary '[]' characters
for element in ${primeArray[@]}; do
    temp=$(echo $element | tr -d "[]")
    let sumOfArray+=$temp
done

#clears the terminal so that final text output is more neat and readable
tput reset

#prints the prime numbers, their count, and their sum. alternatively if no prime numbers are found in the range, user will be advised of this via the terminal.
[[ -z ${primeArray[@]} ]] && echo "no prime number(s) exist within the range $lowerBound and $upperBound" || echo -e "You have selected the range $lowerBound - $upperBound\n
${#primeArray[@]} prime number(s) were found between $lowerBound and $upperBound, these being:\n\n${primeArray[*]}\n
The sum of these prime numbers is $sumOfArray"

exit 0