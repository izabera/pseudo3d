#! /usr/bin/env bash

declare -A infos
hues=(196 197 198 199 200 201 165 129 93 57 21 27 33 39 45 51 50 49 48 47 46 82 118 154 190 226 220 214 208 202)


pi=314159
scale=100000
pisq=98696044010
pi2=628318
pi_2=157079
pi_4=78540

# bhaskara's formula
# see accuracy/perf tests here https://gist.github.com/izabera/df0740b7f4544342c142100d90f96814/
cos () ((REPLY=((pisq-4*$1**2)*scale)/(pisq+$1**2)))
sincos ()
    case $(($1/pi_2)) in
        0) cos "$1"; cos=$REPLY; cos "$((-$1+pi_2))"; sin=$REPLY ;;
        1) cos "$((pi-$1))"; cos=$((-REPLY)); cos "$(($1-pi_2))"; sin=$REPLY ;;
        2) cos "$(($1-pi))"; cos=$((-REPLY)); cos "$((pi_2*3-$1))"; sin=$((-REPLY)) ;;
        3) cos "$(($1-pi2))"; cos=$REPLY; cos "$((pi_2*3-$1))"; sin=$((-REPLY)) ;;
    esac

mapselect=${mapselect-2}
if ((mapselect==1)); then
map=(
    1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
    1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 0 0 0 0 0 2 2 2 2 2 0 0 0 0 3 0 3 0 3 0 0 0 1
    1 0 0 0 0 0 2 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 0 0 0 0 0 2 0 0 0 2 0 0 0 0 3 0 0 0 3 0 0 0 1
    1 0 0 0 0 0 2 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 0 0 0 0 0 2 2 0 2 2 0 0 0 0 3 0 3 0 3 0 0 0 1
    1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 4 4 4 4 4 4 4 4 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 4 0 4 0 0 0 0 4 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 4 0 0 0 0 5 0 4 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 4 0 4 0 0 0 0 4 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 4 0 4 4 4 4 4 4 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 4 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 4 4 4 4 4 4 4 4 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
    1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
)
mapw=24 maph=24
mx=$((22*scale)) my=$((maph/2*scale))
angle=pi
elif ((mapselect==2)); then

map=(
    5 5 5 5 5 5 5 5 5 6 6 6 6 6 6 6 6 6 6 5 5 5 5 5 6 6 6 6 6 6 6 6 6 5 5 5 5 6 6 6 6 6 6 6
    5 0 0 0 0 0 0 0 0 6 6 6 0 6 0 6 0 6 5 0 0 0 0 0 6 0 0 0 6 6 6 6 5 0 0 0 0 7 6 6 6 6 6 6
    5 0 8 0 8 0 8 0 0 0 0 0 0 0 0 0 0 0 0 0 8 8 0 0 6 0 0 0 6 6 6 6 7 0 8 0 0 7 0 0 0 0 0 6
    5 0 0 0 0 0 0 0 0 6 6 6 6 6 0 6 0 6 8 8 8 0 0 0 6 0 7 0 6 6 6 7 0 0 8 8 0 7 0 0 0 0 0 6
    5 0 8 0 8 0 8 0 0 0 0 0 0 6 0 6 0 6 6 6 8 0 0 6 6 0 7 0 6 6 7 0 0 0 0 0 0 7 0 0 0 0 0 6
    5 0 0 0 0 0 0 0 0 5 5 5 0 6 6 6 0 0 6 6 8 0 0 0 0 0 7 0 6 5 0 0 0 7 5 5 5 6 6 6 0 6 6 6
    5 0 8 0 8 0 8 0 0 5 0 5 0 6 6 6 7 0 7 6 6 5 5 5 5 5 7 0 6 7 0 0 7 5 0 0 0 6 6 6 0 6 6 6
    5 0 0 0 0 5 0 0 0 5 0 0 0 6 6 7 0 0 0 7 6 6 6 6 5 0 0 0 6 0 0 7 6 6 7 7 0 6 6 6 0 6 6 6
    5 5 5 0 5 5 6 6 0 5 5 5 0 6 7 0 0 0 0 0 7 6 6 6 5 0 6 6 6 0 0 5 6 6 6 7 0 6 6 0 0 6 6 6
    6 6 8 0 8 6 6 6 0 0 0 0 0 6 7 0 0 8 0 0 7 6 6 6 5 0 0 0 0 0 7 6 6 6 6 7 0 6 0 0 0 6 6 6
    6 7 0 0 0 7 7 6 6 6 6 6 6 6 6 7 0 0 0 7 6 6 6 6 5 0 0 0 0 7 6 6 6 6 6 7 0 0 0 0 6 6 6 6
    6 7 0 0 0 0 7 6 6 6 6 6 6 6 6 6 5 5 5 6 6 6 6 6 6 7 7 7 0 0 5 6 6 6 6 7 0 0 0 6 6 6 6 6
    7 0 0 0 0 0 0 6 7 7 7 7 7 7 7 7 7 7 7 7 7 7 7 6 6 6 6 6 5 0 0 5 6 6 6 7 0 0 6 6 6 6 6 6
    7 0 0 7 7 0 0 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 6 6 6 6 6 5 0 0 5 6 6 7 0 6 6 6 6 6 6 6
    6 7 7 7 6 0 0 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 6 6 6 6 6 6 5 0 0 7 6 7 0 6 6 6 6 6 6 6
    6 6 6 6 0 0 0 5 0 0 8 0 0 0 0 0 0 0 0 0 8 0 0 6 6 6 6 6 6 6 6 5 0 5 6 7 0 6 6 6 6 6 6 6
    6 0 0 0 0 8 0 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 6 6 6 6 6 6 6 0 0 0 6 7 0 0 6 6 6 6 6 6
    6 0 6 6 0 8 0 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 6 6 6 6 6 7 0 0 0 0 0 7 0 0 0 6 6 6 6 6
    6 6 6 0 0 0 0 5 0 0 0 0 0 3 3 0 3 3 0 0 0 0 0 6 6 6 6 6 6 8 0 0 0 0 0 0 0 0 0 0 0 6 6 6
    6 6 0 0 0 6 6 5 0 0 0 0 0 3 0 0 0 3 0 0 0 0 0 6 6 6 6 6 6 7 0 0 0 0 0 7 5 7 6 0 0 0 6 6
    6 0 0 0 6 6 6 5 0 0 0 0 0 3 0 0 0 3 0 0 0 0 0 6 6 6 6 6 6 6 6 0 0 0 6 6 6 6 6 0 0 0 6 6
    6 0 6 6 6 6 6 5 0 0 0 0 0 3 0 0 0 3 0 0 0 0 0 6 6 6 6 6 6 6 6 5 0 5 6 5 5 6 6 6 0 6 6 6
    6 0 6 6 0 0 0 5 0 0 0 0 0 3 3 3 3 3 0 0 0 0 0 6 6 6 5 6 6 6 0 5 0 5 5 0 5 6 6 6 0 6 6 6
    6 0 6 0 0 0 0 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 5 5 0 5 5 6 0 0 0 0 0 0 5 6 6 6 0 6 6 6
    6 0 6 0 0 0 0 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 0 0 0 0 0 5 5 0 0 0 5 5 6 6 6 6 0 6 6 6
    6 0 0 0 0 0 0 5 0 0 8 0 0 0 0 0 0 0 0 0 8 0 0 6 0 0 0 0 0 0 0 0 0 0 6 6 6 6 6 0 0 0 6 6
    6 5 5 5 0 0 0 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 0 0 0 0 0 6 6 0 0 0 5 6 6 6 6 6 0 6 6 6
    6 5 0 0 0 0 0 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 5 5 0 5 5 6 6 6 0 0 0 5 6 6 6 6 0 6 6 6
    6 5 0 0 0 0 0 5 6 6 6 6 6 6 8 0 8 6 6 6 6 6 6 6 6 5 0 5 6 6 6 6 5 6 5 6 6 6 6 6 0 6 6 6
    6 5 0 0 0 6 6 6 6 6 6 6 6 6 8 0 8 6 6 6 6 6 6 5 5 5 0 5 5 5 5 5 5 5 5 6 6 6 6 6 0 6 6 6
    5 0 0 0 6 6 6 6 6 6 6 6 6 6 8 0 8 6 6 6 6 6 6 0 0 0 0 0 0 0 0 0 0 0 5 6 6 6 6 0 0 0 6 6
    7 0 7 6 6 6 6 6 6 6 6 6 6 6 8 0 8 6 6 6 6 6 6 0 0 0 0 0 0 0 0 0 0 0 5 6 6 6 0 0 0 0 0 6
    7 0 7 6 6 6 6 6 6 6 6 6 6 6 8 0 8 6 6 6 6 6 6 0 0 0 0 0 0 0 0 0 0 0 0 5 6 6 0 0 0 0 0 6
    7 0 7 6 6 6 6 6 6 6 6 6 6 6 8 0 8 6 6 6 6 6 6 0 0 0 0 0 0 0 0 0 0 0 0 5 6 6 0 0 0 0 0 6
    7 0 7 6 0 0 0 0 0 0 0 0 6 6 6 0 6 6 6 6 6 6 6 0 0 0 0 0 0 0 0 0 0 0 0 5 6 6 6 0 0 0 6 6
    7 0 7 6 0 0 0 8 8 8 8 8 6 6 6 0 6 6 6 6 6 6 6 5 5 5 5 5 0 0 0 0 0 0 0 5 6 6 6 6 0 6 6 6
    7 0 7 3 0 0 0 8 0 0 0 8 6 6 6 0 6 6 6 6 6 6 6 0 0 0 0 5 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6 6
    7 0 0 0 0 0 0 0 0 0 0 8 6 6 6 0 6 6 6 6 6 6 6 0 0 0 0 5 0 0 0 0 0 0 0 5 6 6 6 8 0 8 6 6
    7 7 7 3 0 0 0 8 0 0 0 8 6 6 6 0 6 6 6 6 6 6 6 0 0 0 0 5 0 0 0 0 0 0 0 5 6 6 8 0 0 0 8 6
    6 6 7 6 0 0 0 8 8 8 8 8 6 6 6 0 0 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 0 0 5 6 8 0 0 0 0 0 8
    6 6 7 6 0 0 0 0 0 0 0 0 6 6 6 6 6 6 6 6 6 6 5 0 0 0 0 0 0 0 0 0 0 0 7 6 6 8 0 0 0 0 0 8
    6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 5 5 5 5 5 3 7 7 7 7 7 7 6 6 6 8 0 0 0 0 0 8
    6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 8 0 0 0 8 6
    6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 6 8 8 8 6 6
)
mapw=44 maph=44
((mx=375*scale/10))
((my=95*scale/10))
angle=$((pi2-pi/2))
else
map=(
    9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 9
    9 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 9
    9 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 9
    9 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 9
    9 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 9
    9 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 9
    9 0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 9
    9 0 0 0 0 0 0 3 0 0 0 0 0 0 0 0 0 9
    9 0 0 0 0 0 0 0 4 0 0 0 0 0 0 0 0 9
    9 0 0 0 0 0 0 0 0 5 0 0 0 0 0 0 0 9
    9 0 0 0 0 0 0 0 0 0 6 0 0 0 0 0 0 9
    9 0 0 0 0 0 0 0 0 0 0 7 0 0 0 0 0 9
    9 0 0 0 0 0 0 0 0 0 0 0 8 0 0 0 0 9
    9 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 9
    9 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 9
    9 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 9
    9 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 9
    9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 9 9
)
mapw=18 maph=18
((mx=scale,my=(maph-1)*scale))
angle=$((pi2-pi/4))
fi

# colours are hard and i don't know what i'm doing
walls=(
    1 2 2
    3 4 1
    4 2 1
    3 0 0
    3 1 2
    4 3 5
    1 0 3
    1 1 5
    0 0 4
)
wallcount=$((${#walls[@]}/3+1))

makecolours ()
for ((i=0;i<${#walls[@]};i+=3)) do
    ((colours[1+i/3]          =walls[i]  *6*6+walls[i+1]  *6+walls[i+2]  +16))
    ((colours[1+i/3+wallcount]=walls[i]/2*6*6+walls[i+1]/2*6+walls[i+2]/2+16))
done
sky=252 grass=239

LANG=C
# for the basic bash game loop: https://gist.github.com/izabera/5e0cc5fcd598f866eb7c6cc955ef3409

FPS=${FPS-30}

shopt -s extglob globasciiranges expand_aliases
gamesetup () {
    stty -echo
    # save cursor pos -> alt screen -> hide cursor -> go to 1;1 -> delete screen
    printf '\e7\e[?1049h\e[?25l\e[H\e[J'
    exitfunc () { printf '\e[?25h\e[?1049l\e[m\e8' >/dev/tty; stty echo; }
    trap exitfunc exit

    # size-dependent vars
    update_sizes () {
        ((rows=LINES-0,cols=COLUMNS-0))

        # see dumbdrawcol
        vspaces=
        halfspaces=
        vblock=$'▀\e[D\e[B'
        for ((i=0;i<rows;i++)) do vspaces+=$' \e[D\e[B'; done
        for ((i=0;i<(rows+1)/2;i++)) do halfspaces+=$' \e[D\e[B'; done
        printf -v hspaces '%*s' "$cols"
    }

    # this condition is dumb
    # previous things already rely on this running in a terminal
    if [[ $TERM ]]; then
        # kitty kbd proto -> da1
        printf '\e[?u\e[c'
        IFS=$'\e[;' read -rdc -a arr
        if [[ ${arr[*]} = *u* ]]; then
            kitty=1
        fi
        get_term_size() {
            __winch=0
            printf '\e[%s\e[6n' '9999;9999H'
            IFS='[;' read -rdR _ LINES COLUMNS
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
    FRAME=0 __start=${EPOCHREALTIME/.}

    nextframe() {
        local deadline wait=$((1000000/FPS)) now sleep
        if ((SKIPPED=0,(now=${EPOCHREALTIME/.})>=(deadline=__start+ ++FRAME*wait))); then
            # you fucked up, your game logic can't run at $FPS
            ((deadline=__start+(FRAME+=(SKIPPED=(now-deadline+wait-1)/wait))*wait))
        fi
        while ((now<deadline)); do
            printf -v sleep 0.%06d "$((deadline-now))"
            read -t "$sleep" -n1 -d '' -r
            __input+=$REPLY now=${EPOCHREALTIME/.}
        done
        INPUT=()
        while [[ $__input ]]; do
            case $__input in
                [$' \t\n\r\b\177']*) INPUT+=("${__keys[${__input::1}]}") __input=${__input:1} ;;
                [[:alnum:][:punct:]]*) INPUT+=("${__input::1}") __input=${__input:1} ;;
                $'\e'*) # handle this separately to avoid making the top level case slower for no reason
                    case $__input in
                    $'\e'[[O][ABCD]*) INPUT+=("${__keys[${__input:2:1}]}") __input=${__input:3} ;; # arrow keys
                    $'\e['*([0-?])*([ -/])[@-~]*) __input=${__input##$'\e['*([0-?])*([ -/])[@-~]} ;; # unsupported csi sequence
                    $'\e'?('[')) break ;; # assume incomplete csi, hopefully it will be resolved by the next read
                    $'\e'[^[]*) __input=${__input:2} ;; # something went super wrong and we got an unrecognised sequence
                    esac ;;
                *) __input=${__input:1} # this was some non ascii unicode character (unsupported for now) or some weird ctrl character
            esac
        done
        if ((__term)); then
            if ((__winch)); then get_term_size; fi
        fi
    }
}

drawmsgs () {
    set -- "${msgs[@]:(${#msgs[@]}>5?-5:0):5}"
    printf '\e[m\e[%s;2H' "$((rows+2-$#))"
    printf "%.$((cols+5))s\r\e[B\e[C" "$@"
}
drawinfo () {
    ((${#infos[@]}))||return
    printf '\e[2;2H\e[m'
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

# dumb function that doesn't know where the horizon is
# two versions because one case is painful
# $1 column
# $2 colour
# $3 starting (half)row
# $4 length

dumbdrawcol () {
    # this is super annoying but it also deals with the case if height == 0
    # and rows % 2 == 1, which needs to print a halfblock of sky/grass
((
skygrass=$4==0&&(rows%2==1),
fullsky=$3/2,
tophalfblock=($3%2==1)*(!skygrass),
bottomhalfblock=(($3+$4)%2==1)*(!skygrass),
fullheight=($4-tophalfblock-bottomhalfblock)/2,
fullgrass=(rows-($3/2+fullheight+tophalfblock+bottomhalfblock+skygrass))
))
    # 7 == length of $' \e[D\e[B'
    # 9 == length of $'▀\e[D\e[B' in LANG=C

    # this code is horrible because this function is more performance-intensive than it looks like,
    # and it takes a ridiculous % of the time if you write it in a less atrocious way
    #
    # what                 | max size
    # ---------------------+-----------
    # ceiling to horizon   | (rows+1)/2
    # tophalf              | 1
    # wall                 | rows
    # bottomhalf           | 1
    # horizon to floor     | (rows+1)/2
    #
    # in ${var:start:len} bash will copy the string before extracting the substring
    # so this could use a long string of $'▀\e[D\e[B' as tall as the screen, but that'd be slower
    # instead we use a specialised version that's shorter

    #       <cursor><----sky----><------tophalf------><----wall---><------skygrass-----><-----bottomhalf----><---grass--->
    printf '\e[1;%sH\e[48;5;%sm%s\e[38;5;%s;48;5;%sm%s\e[48;5;%sm%s\e[38;5;%s;48;5;%sm%s\e[38;5;%s;48;5;%sm%s\e[48;5;%sm%s' \
        "$1" \
        "$sky"          "${halfspaces::7*fullsky}" \
        "$sky" "$2"     "${vblock::9*tophalfblock}" \
        "$2"            "${vspaces::7*fullheight}" \
        "$sky" "$grass" "${vblock::9*skygrass}" \
        "$2"   "$grass" "${vblock::9*bottomhalfblock}" \
        "$grass"        "${halfspaces::7*fullgrass}"
}

# knows where the horizon is
horidrawcol () {
    # $1 column
    # $2 colour
    # $3 height
    local h=$((${3-0}>rows*2?rows*2:${3-0}))
    dumbdrawcol "$1" "$2" "$(((rows*2-h)/2))" "$h"
}

msg= msgs=()
error() { printf -v 'msgs[msg++]' '\e[31m%(%T)T [ERROR]: %s\e[m' -1 "$1"; }
warn () { printf -v 'msgs[msg++]' '\e[33m%(%T)T [WARNING]: %s\e[m' -1 "$1"; }
info () { printf -v 'msgs[msg++]' '\e[34m%(%T)T [INFO]: %s\e[m' -1 "$1"; }

TIMEFORMAT=%R


gamesetup

# horrible horrible horrible horrible
hit='sdx<sdy?
(sdx+=dx,mapX+=sx,side=0):
(sdy+=dy,mapY+=sy,side=1),
map[mapX/scale*mapw+mapY/scale]||hit'

# arbitrary value that's a lot bigger than the map and that doesn't make the maths overflow
# scale**3 was too big :c
((inf=scale**2*10))
drawrays () {
    # fov depends on aspect ratio
    ((planeX=sin*cols/(rows*4),planeY=-cos*cols/(rows*4)))

    for ((x=0;x<cols;x++)) do
((cameraX=2*x*scale/cols-scale,
mapX=mx/scale*scale,mapY=my/scale*scale,
rdx=cos+planeX*cameraX/scale,
rdy=sin+planeY*cameraX/scale,
adX=rdx<0?-rdx:rdx,
adY=rdy<0?-rdy:rdy,
dx=rdx?scale*scale/adX:inf,
dy=rdy?scale*scale/adY:inf,
rdx<0?(sx=-scale,sdx=(mx-mapX)*dx/scale):(sx=scale,sdx=(mapX+scale-mx)*dx/scale),
rdy<0?(sy=-scale,sdy=(my-mapY)*dy/scale):(sy=scale,sdy=(mapY+scale-my)*dy/scale),
hit,dist=side==0?sdx-dx:sdy-dy,height=dist==0?rows*2:rows*2*scale/dist))
horidrawcol "$((x+1))" "$((z=2*dist/scale,(255-(z>23?23:z))))" "$height"
        #horidrawcol "$((x+1))" "${colours[map[mapX/scale*mapw+mapY/scale]+(side*wallcount)]}" "$height"
    done
}


if ((BENCHMARK)); then sincos "$angle"; for i in {1..100}; do drawrays; done; exit; fi

alias nobuffer=${NOBUFFER+#}

speed=0 rspeed=0
while nextframe; do
    ((totalskipped+=SKIPPED))

    for k in "${INPUT[@]}"; do
        case $k in
            q) break 2 ;;
            LEFT)  rspeed=$((scale/20));; #((angle+=scale/20,angle>=pi2&&(angle-=pi2))) ;;
            RIGHT) rspeed=$((-scale/20));; #((angle-=scale/20,angle<0&&(angle+=pi2))) ;;
            UP)   speed=$scale;; #((map[(mx+cos/3)/scale*mapw+my/scale]==0&&(mx+=cos/3), map[mx/scale*mapw+(my+sin/3)/scale]==0&&(my+=sin/3) ));;
            DOWN) speed=-$scale;; #((map[(mx-cos/3)/scale*mapw+my/scale]==0&&(mx-=cos/3), map[mx/scale*mapw+(my-sin/3)/scale]==0&&(my-=sin/3) ));;

            R) ((r+=r<5)) ;; r) ((r-=r>0)) ;;
            G) ((g+=g<5)) ;; g) ((g-=g>0)) ;;
            B) ((b+=b<5)) ;; b) ((b-=b>0)) ;;
            SPACE) ((select=select++%wallcount));;
        esac
    done
    #walls[select*3+0]=$r
    #walls[select*3+1]=$g
    #walls[select*3+2]=$b
    #makecolours
    #((map[(mx-(cos*speed)/scale/3)/scale*mapw+my/scale]==0&&(mx-=cos/3), map[mx/scale*mapw+(my-sin/3)/scale]==0&&(my-=sin/3) ))

    ((angle+=rspeed,angle>=pi2&&(angle-=pi2),angle<0&&(angle+=pi2)))
    sincos "$angle"
    ((map[(mx+cos*speed/scale/3)/scale*mapw+my/scale]==0&&(mx+=cos*speed/scale/3), map[mx/scale*mapw+(my+sin*speed/scale/3)/scale]==0&&(my+=sin*speed/scale/3) ))
    ((speed=speed*2/3,rspeed=rspeed*2/3))

    # screen buffering via external file
    nobuffer {
        #drawborder
        drawrays
        #drawmsgs
        #infos[frame]=$FRAME
        #infos[skipped]=$totalskipped
        #infos[res]=$cols\x$((rows*2))
        drawinfo
    nobuffer } > buffered

    nobuffer read -rd '' < buffered
    nobuffer printf '%s' "$REPLY"
done
