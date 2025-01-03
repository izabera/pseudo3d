dumpstats() {
    # see tests in https://gist.github.com/izabera/3d1e5dfabbe80b3f5f2e50ec6f56eadb
    END=${EPOCHREALTIME/.}
    title () { printf '\e[38;5;201m==== %s ====\e[m\n' "$@"; }
    info () {
        local -A colours=([true]=46 [false]=196)
        printf '%s: \e[38;5;%sm%s\e[m\n' "$1" "${colours[${2:-0}]-33}" "$2"
    }
    note () { echo "note: $*"; }

    title 'frame stats'
    info 'final resolution' "${cols}x$((rows*2))"
    info 'fps target' "$FPS"
    info 'terminated after frame' "$FRAME"

    if ((BENCHMARK)); then
        info 'time per frame' "$(((END-START)/FRAME))µs"
    else
        info 'skipped frames' "$TOTALSKIPPED ($((TOTALSKIPPED*100/FRAME))%)"
    fi
    if ((${#frametimes[@]})); then
        # basic counting sort
        sorted=() sum=0 counted=()
        for n in "${!frametimes[@]}"; do counted[n]=${frametimes[$n]}; done
        for n in "${!counted[@]}"; do
            for ((i=0;i<counted[n];i++)) do
                sorted+=("$n")
                ((sum+=n))
            done
        done

        min=${sorted[0]} max=${sorted[-1]}
        framecount=${#sorted[@]}
        mean=$((sum/framecount))
        sum=0 sqdiffs=()
        for i in "${!sorted[@]}"; do
            ((sum+=(sqdiffs[i]=(sorted[i]-mean)**2)))
        done
        variance=$((sum/framecount))

        # newton's method
        x=$((variance/2))
        while ((x)); do
            ((prev=x,x=(x+variance/x)/2,x==prev)) && break
        done
        stddev=$x

        info 'fastest frame' "$min"µs
        info 'slowest frame' "$max"µs
        info 'average frame' "$mean"µs
        info '95th %ile' "${sorted[framecount*95/100]}"µs
        info 'std dev' "$stddev"µs
        info 'your bash can render up to' "$((1000000/mean))fps"
        note 'times are collected before drawing to the terminal,' \
             'and do not account for any slowness induced by it'
    fi

    title 'terminal info'
    info '$TERM' "$TERM"
    info '$COLORTERM' "$COLORTERM"
    if [[ $DISPLAY ]] && type xprop &>/dev/null; then
        IFS=' ' read -r _ _ _ _ self _ < <(xprop -root _NET_ACTIVE_WINDOW)
        IFS='"' read -r _ _ _ class _ < <(xprop -id "$self" WM_CLASS)
    else
        class=unknown
    fi
    info 'wm class' "$class"

    tf=(false true)
    colours=(256 truecolor)

    info colours "${colours[truecolor]}"
    info 'kitty keyboard proto support' "${tf[kitty]}"
    info 'synchronised output support' "${tf[sync]}"

    #      r      |     g     |     b     | rdx | gdx | bdx
    # ------------+-----------+-----------+-----+-----+----
    # max         | 0->max    | 0         |  0  |  1  |  0
    # max->0      |    max    | 0         | -1  |  0  |  0
    #      0      |    max    | 0->max    |  0  |  0  |  1
    #      0      |    max->0 |    max    |  0  | -1  |  0
    #      0->max |         0 |    max    |  1  |  0  |  0
    #         max |         0 |    max->0 |  0  |  0  | -1

    # walk around an rgb cube on the edges that don't include black or white
    walkcube () {
        local max=$(($1-1)) fmt=$2
        local rdx=4 gdx=2 bdx=0
        local r=max g=0 b=0
        local i j

        for (( i = 0; i < 6; i++ )) do
            for (( j = 0; j < max; j++ )) do
                printf -v 'hues[i*max+j]' "$fmt" \
                    "$(( r += (rdx%6==2)-(rdx%6==5) ))" \
                    "$(( g += (gdx%6==2)-(gdx%6==5) ))" \
                    "$(( b += (bdx%6==2)-(bdx%6==5) ))"
            done
            (( rdx = (rdx+1) % 6, gdx = (gdx+1) % 6, bdx = (bdx+1) % 6 ))
        done
    }

    declare -ai hues
    walkcube 6 '16 + %d*6*6 + %d*6 + %d'

    printf '256 colour test: '
    printf '\e[38;5;%s;48;5;%sm▌' "${hues[@]}"
    printf '\e[m\n'

    unset hues
    walkcube 256 '%d;%d;%d'

    h=${#hues[@]}
    for (( i = 0; i < h; i++ )) do
        (( i % (h/COLUMNS) )) && unset 'hues[i]'
    done

    printf '24bit colour test: '
    printf '\e[38;2;%s;48;2;%sm▌' "${hues[@]}"
    printf '\e[m\n'
    ((truecolor)) || note 'if the 24bit colour test looks ok, set COLORTERM=truecolor'
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
