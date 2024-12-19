#!/bin/bash

hues=(196 197 198 199 200 201 165 129 93 57 21 27 33 39 45 51 50 49 48 47 46 82 118 154 190 226 220 214 208 202)


pi=314159
scale=100000
pisq=98696044010
pi2=628318
pi_2=157079
pi_4=78540
cos () ((REPLY=((pisq-4*$1**2)*scale)/(pisq+$1**2)))
atan() ((x=$1,REPLY=(pi_4*x-(x*(x-scale)*(24470+6630*x/scale)/scale))/scale))
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

# horrible horrible horrible horrible
hit='sideDistX<sideDistY?
     (sideDistX+=deltaDistX,mapX+=stepX,side=0):
     (sideDistY+=deltaDistY,mapY+=stepY,side=1),
     map[mapX/scale*mapw+mapY/scale]>0?1:hit'
mapw=24 maph=24
posX=22 posY=12
dirX=-100000 dirY=0
planeX=0 planeY=66000
((cameraX=200000*x/mapw-1))
((rayDirX=dirX+planeX*cameraX))
((rayDirY=dirY+planeY*cameraX))

LANG=C
# for the basic bash game loop: https://gist.github.com/izabera/5e0cc5fcd598f866eb7c6cc955ef3409

FPS=30

shopt -s extglob globasciiranges expand_aliases
gamesetup () {
    stty -echo
    # save cursor pos -> alt screen -> hide cursor -> go to 1;1 -> delete screen
    printf '\e7\e[?1049h\e[?25l\e[H\e[J'
    exitfunc () { printf '\e[?25h\e[?1049l\e[m\e8' >/dev/tty; stty echo; }
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
    FRAME=0 __start=${EPOCHREALTIME/.}

    nextframe() {
        local deadline wait=$((1000000/${FPS:=60})) now sleep
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
                [$' \t\n\r\b\177']*) INPUT+=("${__keys[${__input::1}]}") __input=${input:1} ;;
                [[:alnum:][:punct:]]*) INPUT+=("${__input::1}") __input=${__input:1} ;;
                $'\e'*) # handle this separately to avoid making the top level case slower for no reason
                    case $__input in
                    $'\e'[[O][ABCD]*) INPUT+=("${__keys[${__input:2:1}]}") __input=${__input:3} ;; # arrow keys
                    $'\e['*([0-?])*([ -/])[@-~]*) __input=${__input##$'\e['*([0-?])*([ -/])[@-~]} ;; # unsupported csi sequence
                    $'\e'?('[')) break ;; # assume incomplete csi, hopefully it will be resolved by the next read
                    $'\e'[^[]*) __input=${__input::2} ;; # something went super wrong and we got an unrecognised sequence
                    esac ;;
                *) __input=${__input::1} # this was some non ascii unicode character (unsupported for now) or some weird ctrl character
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
    for ((i=0;i<rows;i++)) do
        printf '\e[%d;2H\e[48;5;%sm%s' "$((i+2))" "$black" "$hspaces"
    done
    #for ((i=0;i<rows/2;i++)) do
    #    printf '\e[%d;2H\e[48;5;%sm%s' "$((i+2))" "$sky" "$hspaces"
    #done
    #if ((rows%2==1)); then
    #    printf '\e[%d;2H\e[38;5;%s;48;5;%sm%s' "$((i+2))" "$sky" "$grass" "${hspaces// /▀}"
    #    ((i++))
    #fi
    #for ((;i<rows;i++)) do
    #    printf '\e[%d;2H\e[48;5;%sm%s' "$((i+2))" "$grass" "$hspaces"
    #done
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
#info "${cols}x$((rows*2)) calc:${calc}s draw:${draw}s"

drawpx() {
    drawn[$1*cols+$2]=$((${3-196}-16))
    printf '\e[%s;%sH\e[38;5;%s;48;5;%sm▀\e[m' \
        "$(($1/2+1))" "$(($2+1))" \
        "$((drawn[($1&-2)*cols+$2]+16))" \
        "$((drawn[(($1&-2)+1)*cols+$2]+16))"
}
cx=$rows cy=$((cols/2)) angle=0 len=10
mx=$((mapw/2*scale)) my=$((maph/2*scale))
p0x=$((mx*scale)) p0y=$((cy*scale))
drawmappx () {
    drawpx "$((cx-mapw+$1*2))"   "$((cy-maph+$2*2))"   "$3"
    drawpx "$((cx-mapw+$1*2))"   "$((cy-maph+$2*2+1))" "$3"
    drawpx "$((cx-mapw+$1*2+1))" "$((cy-maph+$2*2))"   "$3"
    drawpx "$((cx-mapw+$1*2+1))" "$((cy-maph+$2*2+1))" "$3"
}
drawmap () {
    for ((mapi=0;mapi<maph;mapi++)) do
        for ((mapj=0;mapj<mapw;mapj++)) do
            drawmappx "$mapi" "$mapj" "${map[mapi*mapw+mapj]}"
        done
    done
}
drawray () {
    dir=$((len>0?1:-1))
    for ((i=0;i!=len;i+=dir)) do
        drawpx "$((cx-mapw+mx*2/scale+i*cos/scale))" "$((cy-maph+my*2/scale+i*sin/scale))" "${hues[i*${#hues[@]}/len]}"
    done
    drawmappx "$((mx/scale))" "$((my/scale))" "$sky"
}
alias timedebug=${NOTIMEDEBUG+#}
while nextframe; do
    drawn=()
    ((totalskipped+=SKIPPED))

    drawborder
    #printf '\e[%s;%sH\e[m ' "$((px/2+1))" "$((py+1))"
    for k in "${INPUT[@]}"; do
        case $k in
            q) break 2 ;;
            LEFT)  ((angle+=scale/20,angle>=pi2&&(angle-=pi2))) ;;
            RIGHT) ((angle-=scale/20,angle<0&&(angle+=pi2))) ;;
            UP)   ((map[(mx+cos)/scale*mapw+my/scale]==0&&(mx+=cos), map[mx/scale*mapw+(my+sin)/scale]==0&&(my+=sin) ));;
            DOWN) ((map[(mx-cos)/scale*mapw+my/scale]==0&&(mx-=cos), map[mx/scale*mapw+(my-sin)/scale]==0&&(my-=sin) ));;
        esac
    done

    sincos "$angle"
    {
    drawbg
    drawmap
    drawray
    info "angle=$angle FRAME=$FRAME totalskipped=$totalskipped mx=$mx my=$my ${INPUT[*]}"
    drawmsgs
    } > buffered
    read -rd '' < buffered
    printf '%s' "$REPLY"
done


