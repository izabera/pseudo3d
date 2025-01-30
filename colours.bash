# colours are hard and i don't know what i'm doing
wallsr=(0  32  34 105 107 155 238 232 202 175)
wallsg=(0 223 201 195 114  30  85 116 136 229)
wallsb=(0  20 135 230 230 235 196 123  34  32)

wallcount=${#wallsr[@]}

for ((i=0;i<wallcount*3;i++)) do
    ((wallsr[i+wallcount]=wallsr[i]*3/4))
    ((wallsg[i+wallcount]=wallsg[i]*3/4))
    ((wallsb[i+wallcount]=wallsb[i]*3/4))
done

if ((truecolor)); then
    if [[ $DEPTH ]]; then
        sky='208;208;208' grass='78;78;78'
    else
        sky='142;229;238' grass='17;124;19'
    fi
    alias 256col='#' 24bit=
else
    if [[ $DEPTH ]]; then
        sky=252 grass=239
    else
        sky=152 grass=28
    fi
    alias 256col= 24bit='#'
fi
