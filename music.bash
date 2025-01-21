#!/bin/bash

(($#)) && song=("$@") ||
song=(
    # für elise
    e5:50 ds5:50 e5:50 ds5:50  e5:50  b4:50 d5:50 c5:50  a4:150
    c4:50  e4:50 a4:50  b4:150 e4:50 gs4:50 b4:50 c5:150 e4:50
    e5:50 ds5:50 e5:50 ds5:50  e5:50  b4:50 d5:50 c5:50  a4:150
    c4:50  e4:50 a4:50  b4:150 e4:50  c5:50 b4:50 a4:200

    pause

    c4+e4+g4:200 # I
    b3+d4+g4:200 # V
    c4+e4+a4:200 # vi
    c4+f4+a4:200 # IV

    silence

    g4:66 g4:33 a4 g4 c5 b4:200  # happy birthday to you
    g4:66 g4:33 a4 g4 d5 c5:200  # happy birthday to you
    g4:66 g4:33 g5 e5 c5 b4 a4   # happy birthday dear tom
    f5:66 f5:33 e5 c5 d5 c5:300  # happy birthday to you
)

samples=8000           # sample at 8khz
inter=500              # default note is half a second long (value in ms)
adsr=(18 100 17 10)    # envelope (values in ms ms % ms)

# for now this assumes minimum note length = attack + decay + release
# there will be audible pops if any notes are shorter



# you probably don't need to modify the rest of the script if you just want to play songs :)








player () {
    if [[ -t 1 ]]; then
        if command -v mpv >/dev/null; then
            mpv --no-video \
                --demuxer=rawaudio \
                --demuxer-rawaudio-format=s16le \
                --demuxer-rawaudio-rate="$samples" \
                --demuxer-rawaudio-channels=1 \
                --no-terminal -
        elif command -v ffplay >/dev/null; then
            ffplay \
                -v -8 -nodisp -nostats -hide_banner -autoexit \
                -f s16le -ar "$samples" -ch_layout mono -
        elif command -v aplay >/dev/null; then
            aplay -f S16_LE -r "$samples" -
        fi
    else
        cat
    fi
}

scale=$((32*1024-1))
pi=102941
pi2=205881
pisq=10596760227
pi_2=51470
pi3_2=154411

cosine='(pisq-4*y*y)*scale/(pisq+y*y)'

# yes this is 5 quadrants because pi_2*4==pi2-1
# tom's idea btw
coscalc=(x pi-x x-pi x-pi2 x-pi2)
cosmult=(1  -1   -1    1     1  )
cos=(
    "y=${coscalc[0]},${cosmult[0]%1}cosine"
    "y=${coscalc[1]},${cosmult[1]%1}cosine"
    "y=${coscalc[2]},${cosmult[2]%1}cosine"
    "y=${coscalc[3]},${cosmult[3]%1}cosine"
    "y=${coscalc[4]},${cosmult[4]%1}cosine"
)


umax=$((64*1024))

declare -A binary
for ((i=0;i<umax;i++)) do
    printf -v tmp '\\x%02x\\x%02x' "$((i&0xff))" "$((i>>8))"
    binary[$i]=$tmp binary[$((i-umax))]=$tmp
done

# notes = ['c', 'cs', 'd', 'ds', 'e', 'f', 'fs', 'g', 'gs', 'a', 'as', 'b']
# scale = 32 * 1024 - 1
# a4 = 440 * scale
# a4idx = 12 * 4 + 9
# for i in range(8*12):
#     print(f"[{notes[i%12]}{i//12}]={int(2 ** ((i-a4idx)/12) * a4)}")

declare -A notes=(
[c0]=535792    [cs0]=567652    [d0]=601407    [ds0]=637168    [e0]=675056    [f0]=715197    [fs0]=757725    [g0]=802782     [gs0]=850518     [a0]=901092     [as0]=954674     [b0]=1011442
[c1]=1071585   [cs1]=1135305   [d1]=1202814   [ds1]=1274337   [e1]=1350113   [f1]=1430395   [fs1]=1515450   [g1]=1605564    [gs1]=1701036    [a1]=1802185    [as1]=1909348    [b1]=2022884
[c2]=2143171   [cs2]=2270610   [d2]=2405628   [ds2]=2548674   [e2]=2700226   [f2]=2860790   [fs2]=3030901   [g2]=3211128    [gs2]=3402072    [a2]=3604370    [as2]=3818696    [b2]=4045768
[c3]=4286342   [cs3]=4541221   [d3]=4811256   [ds3]=5097348   [e3]=5400453   [f3]=5721580   [fs3]=6061803   [g3]=6422257    [gs3]=6804144    [a3]=7208740    [as3]=7637393    [b3]=8091537
[c4]=8572684   [cs4]=9082443   [d4]=9622513   [ds4]=10194697  [e4]=10800906  [f4]=11443161  [fs4]=12123607  [g4]=12844514   [gs4]=13608289   [a4]=14417480   [as4]=15274787   [b4]=16183074
[c5]=17145369  [cs5]=18164886  [d5]=19245026  [ds5]=20389395  [e5]=21601812  [f5]=22886322  [fs5]=24247214  [g5]=25689028   [gs5]=27216578   [a5]=28834960   [as5]=30549575   [b5]=32366148
[c6]=34290739  [cs6]=36329773  [d6]=38490053  [ds6]=40778791  [e6]=43203624  [f6]=45772645  [fs6]=48494428  [g6]=51378057   [gs6]=54433156   [a6]=57669920   [as6]=61099151   [b6]=64732296
[c7]=68581479  [cs7]=72659546  [d7]=76980107  [ds7]=81557583  [e7]=86407249  [f7]=91545291  [fs7]=96988857  [g7]=102756115  [gs7]=108866312  [a7]=115339840  [as7]=122198303  [b7]=129464593
)


# todo: make decay optional and calculate the right lengths on each note
envelope='
    j < attack_e  ? j*scale/attack                    :
    j < decay_e   ? scale+(j-attack_e)*decrease/decay :
    j < release_s ? sustain                           :
                    sustain-(j-release_s)*sustain/release
'
envelope=${envelope//[[:space:]]}


((
   attack   = samples*adsr[0]/1000,
   decay    = samples*adsr[1]/1000,
   sustain  = scale  *adsr[2]/100 ,
   release  = samples*adsr[3]/1000,

   attack_e = decay_s   = attack,
   decay_e  = sustain_s = decay + attack_e,

   decrease = sustain - scale,
   ssamples = samples * scale
))

calc='cos[(x=(freq*pi2*t/ssamples)%pi2)/pi_2]'

IFS=+
set -f
for note in "${song[@]}"; do
    [[ $note =~ ([^:]*)(:(.*))? ]]

    freqs=()
    for note in ${BASH_REMATCH[1]}; do
        freqs+=(${notes[$note]})
    done

    notel=$((samples*inter*${BASH_REMATCH[3]:-100}/100000)) \
    release_s=$((notel-release))

    for ((j=0;j<notel;j++,t++)) do
        sample=0
        for freq in "${freqs[@]}"; do
            ((sample+=cos[(x=(freq*pi2*t/ssamples)%pi2)/pi_2]))
        done

        printf %b "${binary[$((sample*envelope/scale/10))]}"
    done
done | player
