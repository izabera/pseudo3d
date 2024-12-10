#!/bin/bash

LANG=C
# for the basic bash game loop: https://gist.github.com/izabera/5e0cc5fcd598f866eb7c6cc955ef3409

FPS=30

shopt -s extglob globasciiranges
gamesetup () {
    # save cursor pos -> alt screen -> hide cursor -> go to 1;1 -> delete screen
    printf '\e7\e[?1049h\e[?25l\e[H\e[J'
    exitfunc () { printf '\e[?25h\e[?1049l\e[m\e8' >/dev/tty; }
    trap exitfunc exit

    # size-dependent vars
    update_sizes () {
        ((rows=LINES-2,cols=COLUMNS-5))
        vspaces=
        for ((i=0;i<rows;i++)) do vspaces+=$'▀\e[D\e[B'; done
        printf -v hspaces '%*s' "$cols"
    }

    if [[ $TERM ]]; then
        #stty raw
        #printf '\e[?%s' 1049h 25l
        #trap 'printf \\e[?%s 1049l 25h; stty sane; exitfunc' exit
        get_term_size() {
            __winch=0
            printf '\e[%s' '9999;9999H'
            IFS='[;' read -srdR -p $'\e[6n' _ LINES COLUMNS
            update_sizes
        }
        get_term_size
        trap __winch=1 WINCH
        __term=1
    else
        __term=0
        get_term_size() {
            LINES=24 COLUMNS=80
            update_sizes
        }
    fi

    declare -gA __keys=(
        [A]=UP [B]=DOWN [C]=RIGHT [D]=LEFT
        [' ']=SPACE [$'\t']=TAB
        [$'\n']=ENTER [$'\r']=ENTER
        [$'\177']=BACKSLASH [$'\b']=BACKSLASH
    )
    FRAME=-1 __start=${EPOCHREALTIME/.}

    nextframe() {
        local deadline wait=$((1000000/${FPS:=60})) now sleep
        if (( SKIPPED = 0, (now=${EPOCHREALTIME/.}) >= (deadline = __start + ++FRAME * wait) )); then
            # you fucked up, your game logic can't run at $FPS
            (( deadline = __start + (FRAME += (SKIPPED = (now - deadline) / wait )) * wait ))
        fi
        while (( now < deadline )); do
            printf -v sleep 0.%06d "$((deadline-now))"
            read -t "$sleep" -n1 -d '' -sr
            __input+=$REPLY now=${EPOCHREALTIME/.}
        done
        INPUT=()
        while [[ $__input ]]; do
            case $__input in
                [$' \t\n\r\b\177']*) INPUT+=("${__keys[${__input::1}]}") __input=${input:1} ;;
                [[:alnum:][:punct:]]*) INPUT+=("${__input::1}") __input=${__input:1} ;;
                $'\e'[[O][ABCD]*) INPUT+=("${__keys[${__input:2:1}]}") __input=${__input:3} ;; # arrow keys
                $'\e['*([0-?])*([ -/])[@-~]*) __input=${__input##$'\e['*([0-?])*([ -/])[@-~]} ;; # unsupported csi sequence
                $'\e'?('[')) break ;; # assume incomplete csi, hopefully it will be resolved by the next read
                $'\e'[^[]*) __input=${__input::2} ;; # something went super wrong and we got an unrecognised sequence
                [[:ascii:]]*) __input=${__input::1} ;; # something went even more wrong and we got some weird ctrl character
                *) break ;; # maybe incomplete unicode character
            esac
        done
        if ((__term)); then
            if ((__winch)); then get_term_size; fi
        fi
    }
}

sky=39 grass=34
grey=247
black=16

drawmsgs () {
    local i
    set -- "${msgs[@]:(${#msgs[@]}>5?-5:0):5}"
    printf '\e[m\e[%s;2H' "$((rows+2-$#))"
    printf "%.$((cols+5))s\r\e[B\e[C" "$@"
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
drawbg () {
    local i
    for ((i=0;i<rows/2;i++)) do
        printf '\e[%d;2H\e[48;5;%sm%s' "$((i+2))" "$sky" "$hspaces"
    done
    for ((;i<rows;i++)) do
        printf '\e[%d;2H\e[48;5;%sm%s' "$((i+2))" "$grass" "$hspaces"
    done
}
# dumb function that doesn't know where the horizon is
# two versions because one case is painful
# $1 column
# $2 colour
# $3 starting (half)row
# $4 length
dumbdrawcol () {
    # this is super annoying but it also deals with the case if height == 0
    # and rows % 2 == 1, which needs to print a halfblock of sky/grass
    #local fullsky skygrass tophalfblock fullheight bottomhalfblock fullgrass
((
skygrass = $4 == 0 && (rows % 2 == 1),
fullsky=$3/2,
tophalfblock=($3%2==1) * (!skygrass),
bottomhalfblock=(($3+$4)%2==1) * (!skygrass),
fullheight=($4-tophalfblock-bottomhalfblock)/2,
fullgrass=(rows-($3/2+fullheight+tophalfblock+bottomhalfblock+skygrass))
))
    printf '\e[2;%sH' "$1"
    # 9 == length of $'▀\e[D\e[B' in LANG=C
    printf '\e[m\e[38;5;%s;48;5;%sm%s' \
        "$sky"   "$sky"   "${vspaces::9*fullsky}" \
        "$sky"   "$2"     "${vspaces::9*tophalfblock}" \
        "$2"     "$2"     "${vspaces::9*fullheight}" \
        "$sky"   "$grass" "${vspaces::9*skygrass}" \
        "$2"     "$grass" "${vspaces::9*bottomhalfblock}" \
        "$grass" "$grass" "${vspaces::9*fullgrass}"
}

# knows where the horizon is
horidrawcol () {
    # $1 column
    # $2 colour
    # $3 height
    dumbdrawcol "$1" "$2" "$(((rows*2-${3-0})/2))" "${3-0}"
}

drawcols () {
    for ((i=0;i<cols;i++)) do
        horidrawcol "$((i+2))" "${columns[@]:i*2:2}"
    done
}

msg= msgs=()
error() { printf -v 'msgs[msg++]' '\e[31m%(%T)T [ERROR]: %s\e[m' -1 "$1"; }
warn () { printf -v 'msgs[msg++]' '\e[33m%(%T)T [WARNING]: %s\e[m' -1 "$1"; }
info () { printf -v 'msgs[msg++]' '\e[34m%(%T)T [INFO]: %s\e[m' -1 "$1"; }

TIMEFORMAT=%R

gamesetup
info "${cols}x$((rows*2)) calc:${calc}s draw:${draw}s"
while nextframe; do
    { time {
        r=$RANDOM
        columns=()
        for ((i=0;i<cols;i++)) do
            columns+=("$((((r+i)%216)+16))" "$(((i%17)))")
        done
    } } 2>time
    ((totalskipped+=SKIPPED))
    read -r calc < time

    {
    { time {
        drawborder
        #drawbg
        drawcols
    }; } 2>time
    read -r draw < time
    info "${cols}x$((rows*2)) calc:${calc}s draw:${draw}s fps goal:$FPS skipped:$totalskipped"
    drawmsgs
    } > buffered; read -rd '' < buffered; printf '%s' "$REPLY"
done
