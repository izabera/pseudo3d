# walk around the edges of the 6x6x6 cube that don't touch either white or black
hues=(196 197 198 199 200 201 165 129 93 57 21 27 33 39 45 51 50 49 48 47 46 82 118 154 190 226 220 214 208 202)

walls=(
    1 2 2
    3 4 1
    4 2 1
    3 0 0
    3 1 2
    4 3 5
    1 0 3
    1 1 5
    0 0 4
)

# colours are hard and i don't know what i'm doing
wallsr=(0  32  34 105 107 155 238 232 202 175)
wallsg=(0 223 201 195 114  30  85 116 136 229)
wallsb=(0  20 135 230 230 235 196 123  34  32)

makecolours ()
for ((i=1;i<${#walls[@]};i++)) do
    ((wallsr[-i]=wallsr[i]*3/4))
    ((wallsg[-i]=wallsg[i]*3/4))
    ((wallsb[-i]=wallsb[i]*3/4))

    ((col256[ i]=16+(wallsr[i]+28)    /55*6*6+(wallsg[i]+28)    /55*6+(wallsb[i]+28)    /55))
    ((col256[-i]=16+(wallsr[i]+28)*3/4/55*6*6+(wallsg[i]+28)*3/4/55*6+(wallsb[i]+28)*3/4/55))
done
makecolours

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
