#!/bin/bash

# basic bash game loop

shopt -s extglob globasciiranges
gamesetup () {
    exitfunc() { :; } # override this if you want something done at exit
    trap exitfunc exit
    if [[ -t 1 ]]; then
        printf '\e[?%s' 1049h 25l
        trap 'printf \\e[?%s 1049l 25h; exitfunc' exit
        get_term_size() {
            printf '\e[%s' '9999;9999H'
            IFS='[;' read -srdR -p $'\e[6n' _ LINES COLUMNS
            __winch=0
        }
        get_term_size
        trap __winch=1 WINCH
        __term=1
    else
        # maybe just exit here
        __term=0
        LINES=24 COLUMNS=80
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
            printf '\e[H\e[2J'
        fi
    }
}


gamesetup
exitfunc () { declare -p FPS FRAME totalinput totalskipped; } # example, not actually required
while nextframe; do
    # current state:
    # - FPS is set (defaults to 60pfs)
    # - we are drawing frame $FRAME
    # - we waited exactly up to the next frame deadline
    # - if your game logic took too long, $SKIPPED frames have been skipped
    # - any input read since the previous frame is available in the $INPUT array
    # - if stdout is a terminal
    #   - we are in the alternate screen
    #   - the screen is clear
    #   - the screen size is available in $COLUMNS and $LINES
    #   - the cursor is at column 1 line 1
    #   - the cursor is invisible
    # - else
    #   - COLUMNS=80 LINES=24 (or whatever you've set them to in some previous frame)


    # write your main loop here


    # example
    totalinput+=("${INPUT[@]}")
    ((totalskipped+=SKIPPED))
    declare -p FPS FRAME INPUT COLUMNS LINES SKIPPED
done
