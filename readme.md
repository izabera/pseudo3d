# a raycaster in bash

https://github.com/user-attachments/assets/51c07747-ff7b-4994-9a57-7657f695ca10

more screenshots/vidoes at https://imgur.com/a/izas-wolfenstein-bash-journey-bAy5zhp

largely a port of https://lodev.org/cgtutor/raycasting.html

use the arrow keys to rotate and move around, and q to quit


### why this was a bit hard

- bash is slow.  this is by far the biggest issue.  it's so slow that you
  cannot possibly achieve an acceptable frame rate if you have to execute even
  a single command per pixel.  this implies that you also cannot keep the state
  of the screen in memory, neither as an array of colours (did you know that
  accessing a random element in an array takes linear time?) nor as a single
  long string (did you know that accessing the nth character in a string takes
  linear time even in LANG=C?), because literally just reading this
  representation to dump it to the screen will take longer than a frame

- bash has no floating point support nor access to a library of maths
  functions. all the maths is done on integers, scaled up by 100000

- terminals are ugly if you use a full character to represent each pixel, so
  this uses unicode half blocks with different foreground and background
  colours, which effectively doubles the vertical resolution.  there is
  unfortunately no way to update only one of the two colours in a cell, nor any
  way to query the current colours of a cell (besides, it would be too slow for
  bash), so every time we write a pixel we need to know the colour of an
  adjacent pixel.  it would be really convenient if bash could store the state
  somehow but alas it cannot

- various misc annoyances:
    - making sure all the terminal is updated at once is not trivial with a
      slow language like bash

    - most terminals are not designed to play video games in (shockingly), so
      you cannot test if a key is currently pressed.  instead you can only get
      a single key that's being held down, usually really slowly debounced and
      with a low limit for continued presses, so you probably get like 5-6
      characters a second.  you cannot even get multiple keys pressed at the
      same time unless some are modifiers.  the kitty keyboard protocol 100%
      fixes all this, and i'm sure it will become a widely implemented standard
      by the year 2100

    - turns out that filling a terminal with colours takes a lot of data.  at
      my normal font size this does ~10mb of i/o per second, which isn't very
      much in the grand scheme of things, but, you know, it's bash

    - bash will never use a single syscall to print a string with more than one
      newline, regardless of the type of file you're writing to.  this is
      pointless and dumb, and it's the reason why this never prints \n and
      always moves the cursor in other ways.  ultimately this ended up printing
      more data than the size your terminal is likely getting in each read, so
      it might not matter too much, but it still bothered me

    - ecma48/vt100/vt200/xterm... were all designed by insane people who hated
      me specifically

    - holy shit i'm bad at maths, i went to uni for this what the fuck

### faq

- q: it fucks things up when i resize the window/it's a flickery mess/it
     generally looks like shite on my terminal
- a: open an issue please

- q: my cpu heats up like crazy/my computer from 2005 slows down to a crawl
- a: try to set the env variable FPS to something less than 30

- q: it doesn't work on my bash < 5
- a: yep

- q: is this code all pure bash?
- a: no.  it also calls stty once at startup to disable echo, and once at exit
     to re enable it

### roadmap

- [x] semi-accurate pseudo 3d
- [x] fluid movement
- [x] decent framerate
- [x] parallel rendering
- [x] 24 bit colours
- [ ] kitty protocol
- [ ] textures
- [ ] objects/enemies
- [ ] sound
