#!/usr/bin/env bash

# bash calls REAP unconditionally after executing the command in every loop construct
# https://git.savannah.gnu.org/cgit/bash.git/tree/execute_cmd.c?id=c5c97b371044a44b701b6efa35984a3e1956344e#n3702
# #define REAP() \
#   do \
#     { \
#       if (job_control == 0 || interactive_shell == 0) \
#         reap_dead_jobs (); \
#     } \
#   while (0)
#
# reap_dead_jobs calls mark_dead_jobs_as_notified
#
# result: if you've ever forked in this shell session, bash will block sigchld
# after executing the body of every loop, and likely unblock it immediately after
#
# the only way to avoid this is to be in an interactive shell with job control
# note: replacing loops with recursion makes things a *lot* slower
#
# this should be safe/correct, but i'm not fully sure
# it is faster in benchmarks so it stays
#
# this is the dumbest thing i've ever written
[[ $- = *i* && $- = *m* ]] || exec bash --norc --noediting --noprofile -im +H +o history ./game.bash

mapselect=${mapselect-2}
source ./maths.bash
source ./maps.bash
source ./colours.bash
source ./util.bash
source ./dispatch.bash


LANG=C
shopt -s extglob globasciiranges expand_aliases

# for the basic bash game loop: https://gist.github.com/izabera/5e0cc5fcd598f866eb7c6cc955ef3409

FPS=${FPS-30}

gamesetup () {
    if [[ ! ( $TERM && -t 0 && -t 1 ) ]]; then
        echo you need a terminal to run this >&2
        exit 1
    fi

    stty -echo raw

    printf %b%.b \
        '\e[?1049h' 'alt screen on' \
        '\e[?25l'   'cursor off'    \
        '\e[?1004h' 'report focus'  \
        '\e[H'      'go to 1;1'     \
        '\e[J'      'erase screen'  \
        '\e[?u'     'kitty kbd'     \
        '\e[c'      'da1'

    IFS=$'\e[;' read -rdc -a arr
    if [[ ${arr[*]} = *u* ]]; then
        kitty=1
    fi

    exitfunc () {
        dispatch exit
        wait
        printf %b%.b >/dev/tty \
            '\e[?1004l' 'focus off' \
            '\e[?25h'   'cursor on' \
            '\e[?1049l' 'alt screen off'

        stty echo sane
        dumpstats
    }
    trap exitfunc exit

    hblock=$'▀\e[D\e[B' # halfblock
    sblock=$' \e[D\e[B' # "space"block (yes i'm very good at naming things)
    hlen=${#hblock} slen=${#sblock}

    # size-dependent vars
    update_sizes () {
        # see dumbdrawcol
        blockfull=$hblock blockhalf=$hblock
        for ((i=0;i<rows;i++)) do blockfull+=$sblock; done
        for ((i=0;i<(rows+1)/2;i++)) do blockhalf+=$sblock; done
    }

    get_term_size() {
        __winch=0
        printf '\e[%s\e[6n' '9999;9999H'
        IFS='[;' read -rdR _ rows cols
        dispatch "${rows@A} ${cols@A}"
        update_sizes
        dispatch update_sizes
    }
    get_term_size
    trap __winch=1 WINCH

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
            ((deadline=START+(FRAME+=(SKIPPED=(now-deadline+wait-1)/wait))*wait,TOTALSKIPPED+=SKIPPED))
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
        if ((__winch)); then get_term_size; fi
    }
}

# this code is horrible because this function is more performance-intensive than it looks like,
# and it takes a ridiculous % of the time if you write it in a less atrocious way
#
# what                 | max size
# ---------------------+-----------
# ceiling to horizon   | (rows+1)/2
# wall                 | rows
# horizon to floor     | (rows+1)/2
#
# in ${var:start:len} bash will copy the string before extracting the substring
# so this could use a long string of $'▀\e[D\e[B' as tall as the screen, but that'd be slower
# instead we use a specialised version that's shorter

#                      <cursor><--ceiling--><--------wall-------><-------floor------->
alias drawcol='printf "\e[1;%sH\e[48;5;%sm%s\e[38;5;%s;48;5;%sm%s\e[38;5;%s;48;5;%sm%s"'
[[ $COLORTERM = *@(truecolor|24bit)* ]] && alias drawcol=${BASH_ALIASES[drawcol]//5/2}

# dumb function that doesn't know where the horizon is
# two versions because one case is painful
# $1 column
# $2 colour
# $3 starting (half)row
# $4 length
dumbdrawcol () {
    # this does not deal correctly with height == 0, so make sure all walls are close by
((hihalf=$3%2,lohalf=($3+$4)%2,
ceiling=$3/2,
wall=($4-hihalf-lohalf)/2,
floor=rows-($3/2+wall+hihalf+lohalf)))
    drawcol \
        "$1" \
        "$sky"          "${blockhalf:hlen:slen*ceiling}" \
        "$sky" "$2"     "${blockfull:hlen*!hihalf:hlen*hihalf+slen*wall}" \
        "$2"   "$grass" "${blockhalf:hlen*!lohalf:hlen*lohalf+slen*floor}"
}


gamesetup

# the wall hit calculation is a horrible recursive expansion
# it is a lot faster than a loop
# when displaying colours, it also stores the right colour in the variable w
hit='(side=sdx<sdy)?(sdx+=dx,mapX+=sx):(sdy+=dy,mapY+=sy),'

if [[ $DEPTH ]]; then
    hit+='map[mapX/scale*mapw+mapY/scale]||hit'
    alias depthmap= nodepthmap='#'
else
    hit+='(w=map[mapX/scale*mapw+mapY/scale])||hit'
    alias depthmap='#' nodepthmap=
fi

drawrays () {
    # fov depends on aspect ratio
    ((planeX=sin*cols/(rows*4),planeY=-cos*cols/(rows*4),begin=cols*tid/NTHR,end=cols*(tid+1)/NTHR))

    for ((x=begin;x<end;x++)) do
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
hit,dist=side?sdx-dx:sdy-dy,h=dist<scale?rows*2:rows*2*scale/dist))

        # depth map
        depthmap 256col dumbdrawcol "$((x+1))" "$((z=2*dist/scale,255-(z>23?23:z)))"            "$(((rows*2-h)/2))" "$h"
        depthmap 24bit  dumbdrawcol "$((x+1))" "$((z=22*dist/scale,z=255-(z>255?255:z)));$z;$z" "$(((rows*2-h)/2))" "$h"

        # wall colours
        nodepthmap 256col dumbdrawcol "$((x+1))" "${col256[w+side*wallcount]}" "$(((rows*2-h)/2))" "$h"
        nodepthmap 24bit  dumbdrawcol "$((x+1))" "${wallsrgb[w+side*wallcount]}" "$(((rows*2-h)/2))" "$h"
    done
}

drawframe () {
    if ((NTHR>1)); then
        dispatch 'drawrays > buffered."$tid"; printf x'
        for ((t=0;t<NTHR;t++)) do
            read -rn1 -u"${notify[t]}"
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
    START=${EPOCHREALTIME/.}
    while ((FRAME++<BENCHMARK)); do drawframe; done
    ((FRAME--))
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
