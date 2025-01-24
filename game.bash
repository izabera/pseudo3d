#!/usr/bin/env bash

[[ -e .config ]] && source ./.config

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
[[ $- = *i* && $- = *m* ]] || exec "$BASH" --norc --noediting --noprofile -im +H +o history ./game.bash

mapselect=${mapselect-4}
source ./maths.bash
source ./maps.bash
source ./util.bash
source ./dispatch.bash


LANG=C LC_ALL=C
shopt -s extglob globasciiranges expand_aliases

# for the basic bash game loop: https://gist.github.com/izabera/5e0cc5fcd598f866eb7c6cc955ef3409

FPS=${FPS-30}

gamesetup () {
    if [[ ! ( $TERM && -t 0 && -t 1 ) ]]; then
        echo you need a terminal to run this >&2
        exit 1
    fi

    stty -echo raw

    # this expects a bunch of modes to always be supported, and queries support for some less common ones
    printf %b%.b \
        '\e[?1049h'         'alt screen on'        \
        '\e[?25l'           'cursor off'           \
        '\e[?1004h'         'report focus'         \
        '\e[m'              'reset colours'        \
        '\e[2J'             'erase screen'         \
        '\e[9999;9999H'     'move to bottom right' \
        '\e[6n'             'query position'       \
        '\e[?u'             'kitty kbd proto'      \
        '\e[?2026$p'        'synchronised output'  \
        '\e[38;5;123m'      '256 colour fg'        \
        '\e[38;2;45;67;89m' 'truecolor fg'         \
        '\eP$qm\x1b\\'      'decrqss m'

    # add some delay before da1 to work around alacritty on windows which for
    # whatever reason replies in the wrong order (da1 before CSI u)
    sleep .01

    printf %b%.b \
        '\e[c'              'da1'                  \
        '\e[m'              'reset colours again'

    read -rdc
    # see tests in https://gist.github.com/izabera/3d1e5dfabbe80b3f5f2e50ec6f56eadb
    ! [[ $REPLY = *u* ]]; kitty=$?
    ! [[ $REPLY = *'2026;2'* ]]; sync=$?
    ! [[ $COLORTERM = *@(24bit|truecolor)* || $REPLY = *38*2*45*67*89*m* ]]; truecolor=$?

    # disambiguate   1
    # eventtypes     2
    # altkeys        4
    # allescapes     8
    # associatedtext 16
    ((kitty)) && printf '\e[>11u'

    exitfunc () {
        dispatch exit
        wait

        ((kitty)) && printf '\e[<u' >/dev/tty
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
    hlen=${#hblock}

    declare -gA column
    # size-dependent vars
    update_sizes () {
        # see dumbdrawcol
        for ((i=1;i<=rows;i++)) do column[$i]=${column[$((i-1))]}$sblock; done
    }

    get_term_size() {
        __winch=0
        rows=${1%;*} cols=${1#*;}
        dispatch "${rows@A} ${cols@A}"
        update_sizes
        dispatch update_sizes
    }

    REPLY=${REPLY%%R*} REPLY=${REPLY##*$'\e['}
    get_term_size "$REPLY"
    trap __winch=1 WINCH

    declare -gA __keys=(
        [A]=UP [B]=DOWN [C]=RIGHT [D]=LEFT
        [1A]=UP [1B]=DOWN [1C]=RIGHT [1D]=LEFT # makes kitty slightly easier
        [' ']=SPACE [$'\t']=TAB
        [$'\n']=ENTER [$'\r']=ENTER
        [$'\177']=BACKSLASH [$'\b']=BACKSLASH
    )
    for i in {32..126}; do
        printf -v oct %03o "$i"
        printf -v "__keys[${i}u]" "\\$oct"
    done
    declare -gA PRESSED=()
    FRAME=0 START=${EPOCHREALTIME/.} TOTALSKIPPED=0 FOCUS=1

    # somehow the least painful way to parse this stuff
    __kittyregex='^..([0-9]*)(;(([^:]*)(:([0-9]*))?))?(.)(.*)'
    #                <--1--->                                 key code
    #                        <--------2------------->?
    #                          <-------3----------->
    #                           <--4-->                       modifier
    #                                  <----5---->?
    #                                    <---6-->             event type
    #                                                 <7>     final character
    #                                                    <8-> rest
    deltat=$((1000000/FPS))
    nextframe() {
        local deadline now tmout tmp
        if ((__winch)); then printf '\e[9999;9999H\e[6n'; fi
        if ((SKIPPED=0,(now=${EPOCHREALTIME/.})>=(deadline=START+ ++FRAME*deltat))); then
            # you fucked up, your game logic can't run at $FPS
            ((deadline=START+(FRAME+=(SKIPPED=(now-deadline+deltat-1)/deltat))*deltat,TOTALSKIPPED+=SKIPPED))
        fi
        while ((now<deadline)); do
            printf -v tmout 0.%06d "$((deadline-now))"
            read -t "$tmout" -n1 -d '' -r
            __input+=$REPLY now=${EPOCHREALTIME/.}
        done
        INPUT=()
        ((kitty)) || PRESSED=()
        while [[ $__input ]]; do
            case $__input in
                [$' \t\n\r\b\177']*) INPUT+=("${__keys[${__input::1}]}") __input=${__input:1} ;;
                [[:alnum:][:punct:]]*) INPUT+=("${__input::1}") __input=${__input:1} ;;
                $'\e['+([0-9])\;+([0-9])R*) tmp=${__input#$'\e['}; get_term_size "${tmp%%R*}"; __input=${__input#*R} ;;
                $'\e['*([^ABCDEFGHPQSu~])[ABCDEFGHPQSu~]*)
                    if ((kitty)); then
                        [[ $__input =~ $__kittyregex ]]
                        __input=${BASH_REMATCH[8]}
                        tmp=${__keys[${BASH_REMATCH[1]}${BASH_REMATCH[7]}]}
                        [[ $tmp ]] || continue
                        [[ $tmp = c && "(${BASH_REMATCH[4]}-1)&4" -ne 0 ]] && exit
                        ((BASH_REMATCH[6]==3)) && unset 'PRESSED[$tmp]' || PRESSED[$tmp]=1
                        continue
                    fi ;;&
                $'\e['I*) __input=${__input:3} FOCUS=1 PRESSED=() ;;
                $'\e['O*) __input=${__input:3} FOCUS=0 PRESSED=() ;;
                $'\e'[[O][ABCD]*) INPUT+=("${__keys[${__input:2:1}]}") __input=${__input:3} ;; # arrow keys
                $'\e['*([0-?])*([ -/])[@-~]*) __input=${__input##$'\e['*([0-?])*([ -/])[@-~]} ;; # unsupported csi sequence
                $'\e'[^[]*) __input=${__input:2} ;; # something went super wrong and we got an unrecognised sequence
                $'\e'*) break ;; # assume incomplete csi, hopefully it will be resolved by the next read
                $'\3'*) exit ;; #^C
                *) __input=${__input:1} # this was some non ascii unicode character (unsupported for now) or some weird ctrl character
            esac
        done
        INPUT+=("${!PRESSED[@]}")
    }
}

gamesetup
source ./colours.bash

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
((truecolor)) && alias drawcol=${BASH_ALIASES[drawcol]//5/2}

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
        "$sky"          "${column[$ceiling]}" \
        "$sky" "$2"     "${hblock[!hihalf]}${column[$wall]}" \
        "$2"   "$grass" "${hblock[!lohalf]}${column[$floor]}"
}


# the wall hit calculation is a horrible recursive expansion
# it is a lot faster than a loop
# when displaying colours, it also stores the right colour in the variable w
hit='(side=sdx<sdy)?(sdx+=dx,mapX+=sx):(sdy+=dy,mapY+=sy),'

if [[ $DEPTH ]]; aliasing "$?" depthmap; then
    hit+='map[mapX/scale*mapw+mapY/scale]||hit'
else
    hit+='(w=map[mapX/scale*mapw+mapY/scale])||hit'
fi

far=$((scale*23/2)) # 11.5 steps away is too far too see
fov=$scale
drawrays () {
    # fov depends on aspect ratio
    ((planeX=sin*fov*cols/(rows*4*scale),planeY=-cos*fov*cols/(rows*4*scale),begin=cols*tid/NTHR,end=cols*(tid+1)/NTHR))

    for ((x=begin;x<end;x++)) do
((cameraX=2*x*scale/cols-scale,
mapX=mx&maskf0,mapY=my&maskf0,
rdx=cos+planeX*cameraX/scale,
rdy=sin+planeY*cameraX/scale,
adX=rdx<0?-rdx:rdx,
adY=rdy<0?-rdy:rdy,
dx=rdx?scale*scale/adX:inf,
dy=rdy?scale*scale/adY:inf,
rdx<0?(sx=-scale,sdx=(mx-mapX)*dx/scale):(sx=scale,sdx=(mapX+scale-mx)*dx/scale),
rdy<0?(sy=-scale,sdy=(my-mapY)*dy/scale):(sy=scale,sdy=(mapY+scale-my)*dy/scale),
hit,w=(w+side*wallcount)&mask0f,
dist=(side?sdx-dx:sdy-dy)*fov/scale,h=dist<scale?rows*2:rows*2*scale/dist,fdist=far-(dist>far?far:dist)))

        # this is not at all how light works but it looks ok
        # dist 0 -> colour 100%
        # dist 11.5 -> colour 0%

        # depth map
        depthmap 256col dumbdrawcol "$((x+1))" "$((255-2*dist/scale))"          "$(((rows*2-h)/2))" "$h"
        depthmap 24bit  dumbdrawcol "$((x+1))" "$((z=255-22*dist/scale));$z;$z" "$(((rows*2-h)/2))" "$h"

        # wall colours
        nodepthmap 256col dumbdrawcol "$((x+1))" "${col256[w]}" "$(((rows*2-h)/2))" "$h"
        nodepthmap 24bit  dumbdrawcol "$((x+1))" "$((wallsr[w]*fdist/far));$((wallsg[w]*fdist/far));$((wallsb[w]*fdist/far))" "$(((rows*2-h)/2))" "$h"
    done
}

[[ $UNBUFFERED ]]; aliasing "$?" unbuffered buffered
((sync)); aliasing "$?" sync
((NTHR>1)); aliasing "$?" multithread singlethread

# maybe this should be disabled if sync is off and we're in multithreaded mode
[[ $MINIMAP ]]; aliasing "$?" minimap
minimap printf -v minimapfmt '%*s' "$mapw"
minimap minimapfmt=${minimapfmt// /'\\e[38;2;%d;%d;%d;48;2;%d;%d;%dm▀'}'\r\n'

declare -A frametimes
drawframe () {
    frame_start=${EPOCHREALTIME/.}
    sync printf '\e[?2026h'

    multithread buffered dispatch 'drawrays > buffered."$tid"; printf x'
    multithread unbuffered dispatch 'drawrays > /dev/tty; printf x'

    minimap local tmp fmt row=$((mx/scale)) col=$((my/scale)) idx saved
    minimap idx=$((row/2*mapw*2+col*2+row%2)) saved=${mapt[idx]} mapt[idx]=2
    minimap printf -v tmp %s "${mapt[@]//*/\${wallsr[&]\} \${wallsg[&]\} \${wallsb[&]\} }"
    minimap eval "printf -v tmp \"$minimapfmt\" $tmp"
    minimap mapt[idx]=$saved

    multithread for ((t=0;t<NTHR;t++)) do
    multithread     read -rn1 -u"${notify[t]}"
    multithread     buffered read -rd '' 'buffered[t]' < buffered."$t"
    multithread done
    multithread buffered printf %s "${buffered[@]}"

    singlethread drawrays

    minimap printf '\e[1;1H%s' "$tmp"

    sync printf '\e[?2026l'
    ((frametimes[$((${EPOCHREALTIME/.}-frame_start))]++))
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


bomb=4
addstate walls{r,g,b}\[{"$bomb","$((wallcount+bomb))"}]{,}
addstate fov

collision='(map[mx/scale*mapw+my/scale]|1)==1'
move='t=pos*speed*deltat/scale**2'
smoothing='speed=speed*3**(deltat/15000)/4**(deltat/15000)'

printf -v movement %s, \
    "${move//pos/mx+cos}" "${collision/mx/t}&&(mx=t)" \
    "${move//pos/my+sin}" "${collision/my/t}&&(my=t)" \
    "$smoothing" "${smoothing//speed/rspeed}"
movement=${movement%,}

bombtimer='wallsg[bomb]=wallsg[bomb+wallcount]=(FRAME*deltat/2500)%255'
bombtimer+=,${bombtimer//wallsg/wallsb}
bombtimer+=,'wallsr[bomb]=200,wallsr[bomb+wallcount]=250'

((
scale_2=scale/2,
scale_5=scale/5,
scale_10=scale/10,
scale_100=scale/100,
scale2=scale*2,
scale5=scale*5,
scale10=scale*10,
scale100=scale*100
))
while nextframe; do
    for k in "${INPUT[@]}"; do
        case $k in
            q) break 2 ;;
            LEFT)  rspeed=$scale_5;;
            RIGHT) rspeed=-$scale_5;;
            UP)   speed=$scale_2;;
            DOWN) speed=-$scale_2;;
            j) ((fov<scale2&&(fov=fov*105/100))); oneshot fov ;;
            k) ((fov>scale_5&&(fov=fov*95/100))); oneshot fov ;;
        esac
    done

    ((angle+=rspeed*deltat/scale,angle>=pi2&&(angle-=pi2),angle<0&&(angle+=pi2)))
    sincos "$angle"

    ((movement,bombtimer))

    drawframe
done
