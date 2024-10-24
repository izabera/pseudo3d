#!/bin/bash

# basic bash game loop

gamesetup () {
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
        exitfunc() { :; } # override this if you want something done at exit
        __term=1
    else
        # maybe just exit here
        __term=0
        LINES=24 COLUMNS=80
    fi

    FRAME=-1
    __start=${EPOCHREALTIME/.}
    nextframe() {
        local deadline wait=$((1000000/${FPS:=60})) now sleep
        if (( SKIPPED = 0, (now=${EPOCHREALTIME/.}) >= (deadline = __start + ++FRAME * wait) )); then
            # you fucked up, your game logic can't run at $FPS
            (( deadline = __start + (FRAME += (SKIPPED = (now - deadline) / wait )) * wait ))
        fi
        INPUT=
        while (( now < deadline )); do
            printf -v sleep 0.%06d "$((deadline-now))"
            read -t "$sleep" -n1 -d '' -sr
            INPUT+=$REPLY now=${EPOCHREALTIME/.}
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
    # - any input read since the previous frame is available in $INPUT
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
    totalinput+=$INPUT
    ((totalskipped+=SKIPPED))
    declare -p FPS FRAME INPUT COLUMNS LINES SKIPPED
done
