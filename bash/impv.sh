impv(){
P_LIST=( "$@" )
#echo "the number of parameter is $#"
for ((i=0; i<$#; i+=2))
do
    if [[ $# -gt 1 ]]
    then
        #echo "this is the first parameter: ${P_LIST[0]}"
        if [[ "${P_LIST[$i+1]}" == *.srt || "${P_LIST[$i+1]}" == *.ass ]]
        then
            mpv "${P_LIST[$i]}" --sub-file "${P_LIST[$i+1]}"
        else impv_music "$@"; break
        fi
    else mpv "$@"
    fi
done
}

impv_music(){
mpv "$@"
}


