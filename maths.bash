pi=314159
scale=100000
pisq=98696044010
pi2=628318
pi_2=157079
pi_4=78540

# bhaskara's formula
# see accuracy/perf tests here https://gist.github.com/izabera/df0740b7f4544342c142100d90f96814/
cos () ((REPLY=((pisq-4*$1**2)*scale)/(pisq+$1**2)))
sincos ()
    case $(($1/pi_2)) in
        0) cos "$1"; cos=$REPLY; cos "$((-$1+pi_2))"; sin=$REPLY ;;
        1) cos "$((pi-$1))"; cos=$((-REPLY)); cos "$(($1-pi_2))"; sin=$REPLY ;;
        2) cos "$(($1-pi))"; cos=$((-REPLY)); cos "$((pi_2*3-$1))"; sin=$((-REPLY)) ;;
        3) cos "$(($1-pi2))"; cos=$REPLY; cos "$((pi_2*3-$1))"; sin=$((-REPLY)) ;;
    esac

# arbitrary value that's a lot bigger than the map and that doesn't make the maths overflow
# scale**3 was too big :c
((inf=scale**2*10))
