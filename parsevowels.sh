#!/bin/bash
#name: JAMES KELSEY  student number: 10585085

#all vowel parsing and results display logic is contained within the parseVowels() function below
parseVowels () {

#sed is used to remove uneccesary punctuation. the output of sed is placed into an array.
arrayParse=($(sed '/[[:punct:]]*/{ s/[^[:alnum:][:space:]]//g}' $1))

#parsing is done with nested loops. the outer loop selects words with four letters or more, the inner loop finds the vowel count of the word.
#grep is used to find the vowel count, and important values are placed into arrays for use later in the script.
for ((x = 0 ; x < ${#arrayParse[@]}; x++)); do
    [[ $(echo "${arrayParse[$x]}" | wc -c) -gt 4 ]] && wordsFourOrMore=$((wordsFourOrMore+1)) || continue
    for ((i = 0 ; i < 6 ; i++)); do
        [[ $(grep -io "a\|e\|i\|o\|u" <<< ${arrayParse[$x]} | wc -l) -eq $i ]] && arrayCount[$i]+=$i && break
    done
    arrayDisplay[$i]+="[${arrayParse[$x]}] "
done

#the result of the vowel count process is displayed, and in the event a particular vowel count has no words associated with it the user will be informed
echo -e "The file contains ${#arrayParse[@]} words, of which $wordsFourOrMore are four letters or more in length. The vowel count for these $wordsFourOrMore words are as follows:\n"
for (( y = 0 ; y < 6 ; y++)); do
    [[ ${#arrayDisplay[$y]} -eq 0 ]] && echo -e "There are no words that contain $y vowels.\n" || echo -e "${#arrayCount[$y]} contain $y vowels, these being:\n${arrayDisplay[$y]}\n"
done
}

#the script prompts the user for a valid file name until one is provided
while true; do
    read -p "Please enter a file name to parse: "
    [[ -z "${REPLY// }" ]] || [[ ! -f $REPLY ]] && echo "A file of this name does not exist in this location. Please try again." || break
done

#the nominated file name is passed to the parseVowels() function   
parseVowels $REPLY