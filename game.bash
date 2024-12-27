#!/usr/bin/env bash

mapselect=${mapselect-2}
source maths.bash
source maps.bash
source colours.bash
source util.bash
source dispatch.bash


LANG=C
shopt -s extglob globasciiranges expand_aliases

# for the basic bash game loop: https://gist.github.com/izabera/5e0cc5fcd598f866eb7c6cc955ef3409

FPS=${FPS-30}

gamesetup () {
    stty -echo

    printf %b%.b \
        '\e[?1049h' 'alt screen on' \
        '\e[?25l'   'cursor off'    \
        '\e[?1004h' 'report focus'  \
        '\e[H'      'go to 1;1'     \
        '\e[J'      'erase screen'

    exitfunc () {
        dispatch exit
        wait
        printf %b%.b >/dev/tty \
            '\e[?1004l' 'focus off' \
            '\e[?25h'   'cursor on' \
            '\e[?1049l' 'alt screen off'

        stty echo
        dumpstats
    }
    trap exitfunc exit

    # size-dependent vars
    update_sizes () {
        ((rows=LINES,cols=COLUMNS))

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
            dispatch "${LINES@A} ${COLUMNS@A}"
            update_sizes
            dispatch update_sizes
        }
        get_term_size
        trap __winch=1 WINCH
        __term=1
    else
        __term=0
        get_term_size() {
            LINES=24 COLUMNS=80
            dispatch "${LINES@A} ${COLUMNS@A}"
            update_sizes
            dispatch update_sizes
        }
    fi

    declare -gA __keys=(
        [A]=UP [B]=DOWN [C]=RIGHT [D]=LEFT
        [' ']=SPACE [$'\t']=TAB
        [$'\n']=ENTER [$'\r']=ENTER
        [$'\177']=BACKSLASH [$'\b']=BACKSLASH
    )
    FRAME=0 START=${EPOCHREALTIME/.} TOTALSKIPPED=0 FOCUS=1


    nextframe() {
        local deadline wait=$((1000000/FPS)) now sleep
        if ((SKIPPED=0,(now=${EPOCHREALTIME/.})>=(deadline=START+ ++FRAME*wait))); then
            # you fucked up, your game logic can't run at $FPS
            ((deadline=START+(FRAME+=(SKIPPED=(now-deadline+wait-1)/wait))*wait))
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
                    $'\e'\[I*) __input=${input:2} FOCUS=1 ;;
                    $'\e'\[O*) __input=${input:2} FOCUS=0 ;;
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


gamesetup

# horrible horrible horrible horrible
hit='sdx<sdy?
(sdx+=dx,mapX+=sx,side=0):
(sdy+=dy,mapY+=sy,side=1),
map[mapX/scale*mapw+mapY/scale]||hit'

drawraysbackend () {
    # fov depends on aspect ratio
    ((planeX=sin*cols/(rows*4),planeY=-cos*cols/(rows*4)))

    for ((x=cols/NTHR*tid;x<cols/NTHR*(tid+1);x++)) do
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

        # depth map
        horidrawcol "$((x+1))" "$((z=2*dist/scale,(255-(z>23?23:z))))" "$height"

        # wall colours
        #horidrawcol "$((x+1))" "${colours[map[mapX/scale*mapw+mapY/scale]+(side*wallcount)]}" "$height"
    done
}

drawrays () {
    if ((NTHR>1)); then
        drawraysbackend > buffered."$tid"
        printf x
    else
        drawraysbackend
    fi
}

drawframe () {
    if ((NTHR>1)); then
        dispatch drawrays
        for ((t=0;t<NTHR;t++)) do read -rn1 -u"${notify[t]}"; done
        for ((t=0;t<NTHR;t++)) do
            read -rd '' 'buffered[t]' < buffered."$t"
        done
        printf %s "${buffered[@]}"
    else
        drawrays
    fi
}

run_listeners

if ((BENCHMARK)); then
    sincos "$angle"
    for i in {1..100}; do drawframe; done
    FRAME=100
    exit
fi

speed=0 rspeed=0


while nextframe; do
    for k in "${INPUT[@]}"; do
        case $k in
            q) break 2 ;;
            LEFT)  rspeed=$((scale/20));;
            RIGHT) rspeed=$((-scale/20));;
            UP)   speed=$scale;;
            DOWN) speed=-$scale;;
        esac
    done

    ((angle+=rspeed*2,angle>=pi2&&(angle-=pi2),angle<0&&(angle+=pi2)))
    sincos "$angle"
    ((tx=mx+cos*speed/scale/3,map[tx/scale*mapw+my/scale]==0&&(mx=tx),
      ty=my+sin*speed/scale/3,map[mx/scale*mapw+ty/scale]==0&&(my=ty),
      speed=speed*2/3,rspeed=rspeed*2/3))
    drawframe
done
