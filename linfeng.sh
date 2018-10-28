#!/bin/sh

get_chapter()
{
    ch=$1
    url_format=$2
    filename=""

    # link format for chapter 464 and 465 are different from other
    if [ ${ch} -eq 464 ];
    then
        wget http://totallyinsanetranlation.com/pmg-chapter-464-insane-laughter/
        echo $?
        return
    fi
    if [ ${ch} -eq 465 ];
    then
        wget http://totallyinsanetranlation.com/pmg-chapter-465-cursed-world/
        echo $?
        return
    fi

    case ${url_format} in
        0)
            # mosty used for chapter <= 450. But may be used in other chapter
            wget http://totallyinsanetranlation.com/chapter-${ch}/
            ;;
        1)
            # mostly used for chapter > 450.
            wget http://totallyinsanetranlation.com/pmg-chapter-${ch}/
            ;;
        2)
            filename=pmg*tchapter-${ch}
            wget http://totallyinsanetranlation.com/pmg-tchapter-${ch}
            ;;
        3)
            filename=pmg*${ch}
            wget http://totallyinsanetranlation.com/pmg-${ch}
            ;;
        4)
            filename=pmg*chapter-${ch}
            wget http://totallyinsanetranlation.com/pmg-%E2%80%8Bchapter-${ch}
            ;;
    esac

    # save return code of wget
    ret=$?

    # sometimes, web page are not stored in index.html.
    # rename this page into index.html to make them similar to others page
    if [ ! -z ${filename} ] && [ -e ${filename} ];
    then
        mv ${filename} index.html
    fi

    # return wget error code
    echo ${ret}
}

url_format=0

process_chapter()
{
    ch=$1
    out="out_${ch}.html"

    rm -f index.html

    # they are 4 kinds of wb link format.
    # All of them will be tried starting from last working one (ie: previous chapter)
    for i in $(seq 0 4);
    do
        format=$(((url_format + i)%5))
        echo "try format ${format}"
        local ret=$(get_chapter ${ch} ${format})

        # No valid url format found.
        if [ $i -eq 4 ] && [ ${ret} -ne 0 ];
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

    html2text -nobs -style pretty -utf8 -width 1000 -o tmp1 index.html
    # remove all html code before chapter title and after end of chapter
    cat tmp1 |grep -i "share story" -B 1000 | grep Chapter -A 1000 > tmp2
    # make html more pretty by adding end of line balise
    sed ':a;N;$!ba;s/\n/<br>\n/g' tmp2 > tmp1
    # extract chapter's title
    title=`head -n 1 tmp1 |sed -e "s/_/ /g"|sed -e "s/<br>//g"`
    # remove unncessary html code (number of comments, etc...)
    tail -n +9 tmp1 > tmp2
    # better html line
    sed 's/--/<hr>/p' tmp2 > tmp1
    sed 's/--//g' tmp1 > tmp2
    head -n -1 tmp2 |uniq > tmp1
    # remove last line "Next_chapter text"
    grep -v "Previous_Chapter | Next_Chapter" tmp1 > tmp2
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
    cat tmp2 >> ${out}
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
