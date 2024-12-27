# walk around the edges of the 6x6x6 cube that don't touch either white or black
hues=(196 197 198 199 200 201 165 129 93 57 21 27 33 39 45 51 50 49 48 47 46 82 118 154 190 226 220 214 208 202)

# colours are hard and i don't know what i'm doing
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
wallcount=$((${#walls[@]}/3+1))

makecolours ()
for ((i=0;i<${#walls[@]};i+=3)) do
    ((colours[1+i/3]          =walls[i]  *6*6+walls[i+1]  *6+walls[i+2]  +16))
    ((colours[1+i/3+wallcount]=walls[i]/2*6*6+walls[i+1]/2*6+walls[i+2]/2+16))
done
makecolours

sky=252 grass=239
