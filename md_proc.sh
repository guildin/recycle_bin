#!/bin/bash

TMP_CONTENTS=/tmp/contents.md
TMP_FULLTEXT=/tmp/tmp.md
OUTFILE=/target/manual.md

CHAPTER=0
SECTION=0

section_link () {
  LINK_STR=$(echo ${line,,} | \
               tr " " "-" | \
               tr -d '#' | \
               tr -d '*' | \
               tr -d '(' | \
               tr -d ')' | \
               tr -d '[:space:]' | \
               tr -d '.' | \
               sed 's/-//1' )
}

parse_line () {
(( $COMMENT == 1 )) && exit 1
  DIEZ_COUNT=$(tr -dc '#' <<<"$line" | awk '{ print length; }' )
    case $DIEZ_COUNT in
        "" ) # no code section
          ;;
        1 ) 
        ((CHAPTER=CHAPTER+1))
        SECTION=0
        section_link
        printf "\n[$CHAPTER. ${line:1}](#${LINK_STR})\n" >> $TMP_CONTENTS
          ;; 
        2 ) 
        section_link
        ((SECTION=SECTION+1))
        printf "\n[$CHAPTER.$SECTION${line:2}](#${LINK_STR})\n" >> $TMP_CONTENTS
          ;;                            
        3 ) 
        section_link
        printf "  * [${line:3}](#${LINK_STR})\n" >> $TMP_CONTENTS
          ;;
        * ) 
        echo "abnormal count of #: $DIEZ_COUNT" in $file line $LINECNT
        echo $line
        exit 1 
          ;; # porn
    esac
}

mkdir -p $(dirname $OUTFILE)
rm -f ${TMP_CONTENTS}; touch ${TMP_CONTENTS} || : # new concat file anyway
rm -f ${TMP_FULLTEXT}; touch ${TMP_FULLTEXT} || : # new concat file anyway

# search md sources in [00-99]* named folders
for file in $(find ./ -type f -name "[0-9][0-9]*.md"); do
  COMMENT=0
  [ "$file" == "README.md" ] && { echo "Skipping README.md"; continue; } # redundant
  LINECNT=0 # 4debug
  while read -r line; do 
  [ -z "$line" ] && continue
  echo "$line" >> $TMP_FULLTEXT
    (( LINECNT++ )) 
    SYM_COUNT=$(tr -dc '`' <<<"$line" | awk '{ print length; }' ) # check if there is code section starts / ends (```)
    case $SYM_COUNT in
        "" ) SWITCHCOMMENT=0 ;; # no code section line
        3 ) SWITCHCOMMENT=1 ;; # code section line
        6 ) COMMENT=1 ;;       # oneline code section, do no process
        12 ) COMMENT=1 ;;      # two oneline code sections, do no process
        * ) echo "abnormal count code sections $SYM_COUNT"; exit 1 ;; # porn
    esac
    (( $SWITCHCOMMENT == 1 && $COMMENT == 0 )) && { COMMENT=1; continue; } || :; # code section started
    (( $SWITCHCOMMENT == 1 && $COMMENT == 1 )) && { COMMENT=0; continue; } || :; # code section ended
    (( $COMMENT == 0 )) && parse_line || continue
  done < $file

  echo "FILE: $file parsed"
done

cat $TMP_CONTENTS > $OUTFILE
cat $TMP_FULLTEXT >> $OUTFILE

rm -f $TMP_CONTENTS $TMP_FULLTEXT
