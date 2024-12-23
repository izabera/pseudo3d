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

colours=(
    0 196 36 220 21 201
    0 160 28 184 20 165
)

mapw=24 maph=24

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
        vspaces=
        for ((i=0;i<rows;i++)) do vspaces+=$'▀\e[D\e[B'; done
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

sky=39 grass=34

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
    printf '\e[1;%sH' "$1"
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
    local h=$((${3-0}>rows*2?rows*2:${3-0}))
    dumbdrawcol "$1" "$2" "$(((rows*2-h)/2))" "$h"
}

msg= msgs=()
error() { printf -v 'msgs[msg++]' '\e[31m%(%T)T [ERROR]: %s\e[m' -1 "$1"; }
warn () { printf -v 'msgs[msg++]' '\e[33m%(%T)T [WARNING]: %s\e[m' -1 "$1"; }
info () { printf -v 'msgs[msg++]' '\e[34m%(%T)T [INFO]: %s\e[m' -1 "$1"; }

TIMEFORMAT=%R


gamesetup

angle=pi len=10
mx=$((22*scale)) my=$((maph/2*scale))

# horrible horrible horrible horrible
hit='sideDistX<sideDistY?
     (sideDistX+=deltaDistX,mapX+=stepX,side=0):
     (sideDistY+=deltaDistY,mapY+=stepY,side=1),
     map[mapX/scale*mapw+mapY/scale]>0?1:hit'

drawrays () {
    # fov depends on aspect ratio
    ((planeX=sin*cols/(rows*4),planeY=-cos*cols/(rows*4)))

    for ((x = 0; x < cols; x++)) do
        ((cameraX=2*x*scale/cols-scale,
          mapX=mx/scale*scale,mapY=my/scale*scale,
          rayDirX=cos+planeX*cameraX/scale,
          rayDirY=sin+planeY*cameraX/scale,
          absDirX=rayDirX<0?-rayDirX:rayDirX,
          absDirY=rayDirY<0?-rayDirY:rayDirY,
          deltaDistX=rayDirX?scale*scale/absDirX:scale**3,
          deltaDistY=rayDirY?scale*scale/absDirY:scale**3))

        if ((rayDirX<0)); then
            stepX=-$scale
            ((sideDistX=(mx-mapX)*deltaDistX/scale))
        else
            stepX=$scale
            ((sideDistX=(mapX+scale-mx)*deltaDistX/scale))
        fi

        if ((rayDirY<0)); then
            stepY=-$scale
            ((sideDistY=(my-mapY)*deltaDistY/scale))
        else
            stepY=$scale
            ((sideDistY=(mapY+scale-my)*deltaDistY/scale))
        fi

        ((hit))
        ((dist=side==0?sideDistX-deltaDistX:sideDistY-deltaDistY,height=rows*2*scale/dist))
        horidrawcol "$((x+1))" "${colours[map[mapX/scale*mapw+mapY/scale]+(side*6)]}" "$height"
    done
}

while nextframe; do
    ((totalskipped+=SKIPPED))

    for k in "${INPUT[@]}"; do
        case $k in
            q) break 2 ;;
            LEFT)  ((angle+=scale/20,angle>=pi2&&(angle-=pi2))) ;;
            RIGHT) ((angle-=scale/20,angle<0&&(angle+=pi2))) ;;
            UP)   ((map[(mx+cos/3)/scale*mapw+my/scale]==0&&(mx+=cos/3), map[mx/scale*mapw+(my+sin/3)/scale]==0&&(my+=sin/3) ));;
            DOWN) ((map[(mx-cos/3)/scale*mapw+my/scale]==0&&(mx-=cos/3), map[mx/scale*mapw+(my-sin/3)/scale]==0&&(my-=sin/3) ));;
        esac
    done

    sincos "$angle"

    # screen buffering via external file
    {
        #drawborder
        drawrays
        #drawmsgs
        infos[frame]=$FRAME
        infos[skipped]=$totalskipped
        infos[res]=$cols\x$((rows*2))
        drawinfo
    } > buffered

    read -rd '' < buffered
    printf '%s' "$REPLY"
done
