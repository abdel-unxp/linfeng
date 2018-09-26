#!/bin/sh

process_chapter()
{
    ch=$1
    out="out_${ch}.html"

    rm -f index.html
    if [ ${ch} -le 450 ]
    then
        wget http://totallyinsanetranlation.com/chapter-${ch}/
    else
        wget http://totallyinsanetranlation.com/pmg-chapter-${ch}/
    fi
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
i=0
for i in `seq 1 2165`
do
    if [ $(( $i  % 300 )) -eq 0 ]
    then
        j=$(($i-1))
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
    echo "generate last epub $i"
    #pandoc -f html -t epub3 --epub-metadata=metadata.xml --epub-cover-image=cover1.jpg -o linfeng_$i.epub ${outputs}
    pandoc -f html -t epub3  -o linfeng_$i.epub ${outputs}
fi
