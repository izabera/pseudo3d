dumpstats() {
    END=${EPOCHREALTIME/.}
    echo "final resolution: ${cols}x$((rows*2))"
    echo "terminal: $TERM"
    type xprop &>/dev/null &&
    xprop -id "$(xprop -root _NET_ACTIVE_WINDOW | cut -d ' ' -f 5)" WM_CLASS
    echo "colours: ${COLORTERM-256}"
    echo "fps target: $FPS"
    echo "terminated after frame: $FRAME"
    if ((BENCHMARK)); then
        echo "time per frame: $(((END-START)/FRAME))µs"
    else
        echo "skipped frames: $TOTALSKIPPED ($((TOTALSKIPPED*100/FRAME))%)"
    fi
}

drawmsgs () {
    set -- "${msgs[@]:(${#msgs[@]}>5?-5:0):5}"
    printf '\e[m\e[%s;2H' "$((rows+2-$#))"
    printf "%.$((cols+5))s\r\e[B\e[C" "$@"
}
declare -A infos
drawinfo () {
    ((${#infos[@]}))||return
    printf '\e[1;1H\e[m'
    printf '%s=%s\t' "${infos[@]@k}"
}
drawborder () {
    local i
    printf '\e[H'
    printf '+%s+\e[K\r\e[B' "${hspaces// /-}"
    for ((i=1;i<=rows;i++)) do
        printf '|\e[%sC|%d\e[K\r\e[B' "$cols" "$i"
    done
    printf '+%s+\e[K\r\e[B' "${hspaces// /-}"
}

infos=()
msg= msgs=()
error() { printf -v 'msgs[msg++]' '\e[31m%(%T)T [ERROR]: %s\e[m' -1 "$1"; }
warn () { printf -v 'msgs[msg++]' '\e[33m%(%T)T [WARNING]: %s\e[m' -1 "$1"; }
info () { printf -v 'msgs[msg++]' '\e[34m%(%T)T [INFO]: %s\e[m' -1 "$1"; }
