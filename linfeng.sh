#!/bin/sh

get_chapter()
{
    ch=$1
    url_format=$2
    filename=""

    case ${url_format} in
        0)
            # mosty used for chapter <= 411. But may be used in other chapter
            wget https://totallytranslations.com/pmg-chapter-${ch}
            ;;
        1)
            # mostly used for chapter >= 411.
            filename=chapter-${ch}
            wget https://totallytranslations.com/chapter-${ch}
            ;;
        2)
            filename=pmg*chapter-${ch}
            wget https://totallytranslations.com/pmg-%E2%80%8Bchapter-${ch}
            ;;
        3)
            filename=pmg-tchapter-${ch}
            wget https://totallytranslations.com/pmg-tchapter-${ch}
            ;;
    esac

    # save return code of wget
    ret=$?

    # sometimes, web page are not stored in index.html.
    # rename this page into index.html to make them similar to others page
    if [ ! -z ${filename} ] && [ -e ${filename} ];
    then
        mv ${filename} pmg-chapter-${ch}
    fi

    # return wget error code
    echo ${ret}
}

url_format=0

process_chapter()
{
    ch=$1
    out="out_${ch}.html"

    # they are 3 kinds of wb link format.
    # All of them will be tried starting from last working one (ie: previous chapter)
    for i in $(seq 0 3);
    do
        format=$(((url_format + i)%4))
        echo "try format ${format}"
        local ret=$(get_chapter ${ch} ${format})

        # No valid url format found.
        if [ $i -eq 3 ] && [ ${ret} -ne 0 ];
        then
            echo "********* ERROR on chapter ${ch} ******"
            exit 1
        fi

        # ok got a valid url format.
        if [ ${ret} -eq 0 ];
        then
            # remember last working link format
            url_format=${format}
            break
        fi

    done

    html2text -nobs -style pretty -utf8 -width 1000 -o tmp1 pmg-chapter-${ch}
    # remove all html code before chapter title and after end of chapter
    cat tmp1 |grep -i "previous_chapter\|next_chapter" -B 10000 | grep -i "Chapter.*${ch}" -A 10000 > tmp2
    # make html more pretty by adding end of line balise
    sed ':a;N;$!ba;s/\n/<br>\n/g' tmp2 > tmp1
    # extract chapter's title
    title=`head -n 1 tmp1 |sed -e "s/_/ /g"|sed -e "s/<br>//g"`
    # remove unncessary html code (number of comments, etc...)
    # better html line
    sed 's/--/<hr>/p' tmp1 > tmp2
    sed 's/--//g' tmp2 > tmp1
    # remove repeated title
    grep  -i -v "Chapter.*${ch}" tmp1 |uniq > tmp2
    # remove last line "Next_chapter text"
    grep -i -v "Previous_Chapter" tmp2 | grep -i -v "Next_Chapter" | grep -i -v "Add to Library" > tmp1

    # check for empty page
    if [ $(wc -l < tmp1) -le 10 ];
    then
        echo "************* ERROR on empty chapter ${ch}"
        exit 1
    fi

    echo '<html lang="en-US">' > ${out}
    echo '<head>' >> ${out}
    echo '<meta charset="UTF-8" />' >> ${out}
    echo '</head>' >> ${out}
    echo '<body>' >> ${out}
    echo "<h1>${title}</h1>" >> ${out}
    echo '<p>' >> ${out}
    cat tmp1 >> ${out}
    echo '</p>' >> ${out}
    echo '</body>' >> ${out}
}

outputs=""
for i in `seq 1 2195`
do
    if [ $(( $i  % 300 )) -eq 0 ]
    then
        j=$((1 + ($i-1)/300))
        echo "generate epub $j"
        pandoc -f html -t epub3  -o linfeng_$j.epub ${outputs}
        #pandoc -f html -t epub3 --epub-metadata=metadata.xml --epub-cover-image=cover1.jpg -o linfeng_$j.epub ${outputs}
        outputs=""
    fi

    outputs="${outputs} out_$i.html"
    [ -f "out_$i.html" ] && continue
    echo "process chapter $i"
    process_chapter $i

done;

if [ ! -z "${outputs}" ]
then
    j=$((1 + ($i-1)/300))
    echo "generate last epub $j"
    #pandoc -f html -t epub3 --epub-metadata=metadata.xml --epub-cover-image=cover1.jpg -o linfeng_$i.epub ${outputs}
    pandoc -f html -t epub3  -o linfeng_$i.epub ${outputs}
fi
