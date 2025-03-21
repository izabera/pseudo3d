# basic support for multiple rendering processes
# a dispatcher serialises the state of the world (or the changes since the previous frame)
# and sends commands to each rendering process
dispatch () {
    local serial fd
    eval "printf -v serial %s\  ${state[*]/*/&=\"\${&@Q\}\"}"
    for fd in "${dispatch[@]}"; do
        echo "$serial; $*" >&"$fd"
    done
    for _ in "${oneshot[@]}"; do
        unset "state[$_]"
    done
}
listener () {
    tid=$1
    while read -r; do
        eval "$REPLY"
    done
}
declare -A state
addstate () for _ do state[$_]=$_; done
clearstate () for _ do unset "state[$_]"; done
oneshot () { addstate "$@"; oneshot+=("$@"); }
addstate sin cos mx my

NTHR=${NTHR-4}

run_listeners () {
    ((NTHR>1)) &&
    for ((thread=0;thread<NTHR;thread++)) do
        # bash properly supports one coproc at a time
        # then it gets confused and forgets to clean processes up etc
        # however we just need it to spawn the processes and gives us a pair of fds
        # then we can cleanup manually
        # (also we need to silence an error message that can't be avoided)
        { coproc tmp { listener "$thread" 2>>err; }; } 2>/dev/null
        notify[thread]=${tmp[0]}
        dispatch[thread]=${tmp[1]}
    done
}
