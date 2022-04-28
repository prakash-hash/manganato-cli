#! /bin/bash

# Note - Comments starting from # are normal comments
# and which starts with ## are commands just used for
# debugging purposes

# Taking input from user
TITLE=$1

# Removing spaces and joining all the words present in input ex. tokyo ghoul -> tokyo_ghoul
TITLE=${TITLE// /_}

# Presenting a list of mangas similar to the query given
curl -s https://manganato.com/search/story/$TITLE | grep item-title | grep -no  '>.*<' | tr -d ">|<"

# Extracting the unique urls associated with each manga title and storing in an array
URLS=($(curl -s https://manganato.com/search/story/$TITLE | grep item-title | grep -Eo "https://(readmanganato|manganato).com/manga-[a-z]{2}[0-9]{6}"))

# List of modified title (ex. Kaiju No. 8 -> Kaiju_No._8 )to help in creating the folder
LIST=($(curl -s https://manganato.com/search/story/${TITLE} | grep item-title | grep -o 'title=".*"' | grep -o '\".*\"' | tr '\ :' '_' | tr '"' ' ' ))


# Selecting the index of the manga user wants to read
printf "SELECT FROM ABOVE : "
# This it the index value we are reading from user and will use in our URL array
read CHOICE

clear

# Extracting chapter list
CHAPTER_LIST=$(curl -s ${URLS[(CHOICE-1)]} | grep chapter-name | grep -Po "chapter-([0-9]{1,4}+\.[0-9]|[0-9]{1,4})" )

# Extracting the starting index from where manga starts
START=$(echo $CHAPTER_LIST | grep -Eo "chapter-([0-9]{1,4}+\.[0-9]|[0-9]{1,4})"| tail -3)

# Extracting the last index
LAST=$(echo $CHAPTER_LIST | grep -Eo "chapter-([0-9]{1,4}+\.[0-9]|[0-9]{1,4})"| head -2)


# Taking input of chapter number
printf "ENTER CHAPTER NO. OR ENTER 'all' to download all chapters \n$LAST \n.\n.\n.\n$START\n:"
read CHAPTER_CHOICE

# Fetching the pages url corresponding to the chapter

download_chpater(){
    PAGES=($(curl -s https://readmanganato.com/${URLS[(CHOICE-1)]}/chapter-$1 | grep -Eo '(http|https)://[^"]+' | grep chapter_))
    
    # Making Folder where we will store our downloaded manga
    mkdir -p ${LIST[(CHOICE-1)]}/$1
    
    # counter varibale to track the number of each page
    COUNTER=1
    
    # for loop to download the pages
    for PAGE in ${PAGES[@]}
    do
        ## echo $PAGE
        printf "Downloading Chapter - $1 Pages -> $COUNTER/${#PAGES[@]}\r"
        curl -s --output "${LIST[(CHOICE-1)]}/$1/page_$((COUNTER++)).jpg" $PAGE -H 'Referer: https://readmanganato.com/'
    done
    printf "Downloading Chapter - $1 Finished \n"
    
    if [[ $2 == '-p' ]]
    then
        # printf 'pdf compiled\n'
        img2pdf --output "${LIST[(CHOICE-1)]}/$1.pdf" $(ls -v ${LIST[(CHOICE-1)]}/$1/*)
    fi
}

clear
if [[ $CHAPTER_CHOICE == "all" ]]
then
    printf "Downloading all chapters please wait \n"
    for CHAPTER in $(echo $CHAPTER_LIST | grep -Eo "([0-9]{1,4}+\.[0-9]|[0-9]{1,4})" | sort -g)
    do
        # printf "Downloading Chapter - $CHAPTER\n"
        download_chpater $CHAPTER $2
    done
else
    for CHAPTER in $CHAPTER_CHOICE
    do download_chpater $CHAPTER $2
    done
    # download_chpater $CHAPTER_CHOICE
fi

# Combining the pages into a pdf (requires "img2pdf" package)


notify-send "Manga Download Finished"


## echo "https://manganato.com/search/story/${TITLE// /_}"
