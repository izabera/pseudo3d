#!/bin/bash

# basic bash game loop

gamesetup () {
    if [[ -t 1 ]]; then
        printf '\e[?%s' 1049h 25l
        trap 'printf \\e[?%s 1049l 25h; exitfunc' exit
        get_term_size() {
            printf '\e[%s' '9999;9999H'
            IFS='[;' read -sdR -p $'\e[6n' _ LINES COLUMNS
            __winch=0
        }
        get_term_size
        trap __winch=1 WINCH
        exitfunc() { :; } # override this
        __term=1
    else
        # maybe just exit here
        __term=0
        LINES=24 COLUMNS=80
    fi

    FRAME=-1
    __start=${EPOCHREALTIME/.}
    nextframe() {
        local deadline waittime=$((1000000/${FPS-60})) now sleep
        INPUT=
        (( deadline = __start + ++FRAME * waittime ))
        while (( (now=${EPOCHREALTIME/.}) < deadline )); do
            printf -v sleep 0.%06d "$((deadline-now))"
            IFS= read -t "$sleep" -n1 -d '' -s
            INPUT+=$REPLY
        done
        if ((__term)); then
            if ((__winch)); then get_term_size; fi
            printf '\e[H\e[2J'
        fi
    }
}


gamesetup
exitfunc () { declare -p FRAME totalinput; } # example
while nextframe; do
    # current state:
    # - we waited up to 1/$FPS seconds (defaults to 60fps)
    # - we are drawing frame $FRAME
    # - any input read in the previous frame is available in $INPUT
    # - if stdout is a terminal
    #   - we are in the alternate screen
    #   - the screen is clear
    #   - the screen size is available in $COLUMNS and $LINES
    #   - the cursor is at column 1 line 1
    #   - the cursor is invisible
    # - else
    #   - COLUMNS=80 LINES=24


    # write your main loop here


    # example
    totalinput+=$INPUT
    declare -p FRAME INPUT COLUMNS LINES
done