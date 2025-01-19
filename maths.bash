pi=205667
scale=65536
maskf0=-$scale
mask0f=$((scale-1))
shift=16
pisq=42389628127
pi2=411775
pi_2=102944
pi_4=51472
pi3_2=308831

# bhaskara's formula
# see accuracy/perf tests here https://gist.github.com/izabera/df0740b7f4544342c142100d90f96814/
#
# equivalent to this
# cos () ((REPLY=((pisq-4*$1**2)*scale)/(pisq+$1**2)))
# sincos ()
#     case $(($1/pi_2)) in
#         0) cos "$1"         ; cos=$REPLY     ; cos "$((pi_2-$1))"  ; sin=$REPLY      ;;
#         1) cos "$((pi-$1))" ; cos=$((-REPLY)); cos "$(($1-pi_2))"  ; sin=$REPLY      ;;
#         2) cos "$(($1-pi))" ; cos=$((-REPLY)); cos "$((pi_2*3-$1))"; sin=$((-REPLY)) ;;
#         3) cos "$(($1-pi2))"; cos=$REPLY     ; cos "$((pi_2*3-$1))"; sin=$((-REPLY)) ;;
#     esac
cosine='(pisq-4*y*y)*scale/(pisq+y*y)'

coscalc=(x         pi-x      x-pi       x-pi2  )
sincalc=(pi_2-x    x-pi_2    pi3_2-x    pi3_2-x)
cosmult=(1 -1 -1  1)
sinmult=(1  1 -1 -1)

# sincos () ((q=$1/pi_2,x=$1,y=coscalc[q],cos=cosine*cosmult[q],y=sincalc[q],sin=cosine*sinmult[q]))

sincos=(
    "y=${coscalc[0]},cos=${cosmult[0]%1}cosine,y=${sincalc[0]},sin=${sinmult[0]%1}cosine"
    "y=${coscalc[1]},cos=${cosmult[1]%1}cosine,y=${sincalc[1]},sin=${sinmult[1]%1}cosine"
    "y=${coscalc[2]},cos=${cosmult[2]%1}cosine,y=${sincalc[2]},sin=${sinmult[2]%1}cosine"
    "y=${coscalc[3]},cos=${cosmult[3]%1}cosine,y=${sincalc[3]},sin=${sinmult[3]%1}cosine"
)
sincos () ((x=$1,sincos[$1/pi_2]))

# arbitrary value that's a lot bigger than the map and that doesn't make the maths overflow
# scale**3 was too big :c
((inf=scale**2*10))
