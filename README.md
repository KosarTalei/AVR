# AVR assembly
Implementing water pomp that:
switch T: pomp is full
switch B: pomp is empty
switch P: if turned on, pomp will be filling
Light L: blinks from start to end until pomp is full

when switch P pressed, switch B will turn off, and light L will be on. After 1min pomp is full, so switch T is on and light L is off. Pomp will be rest for 1s after each 10s. When pomp is full, switch L turn off, and after 2s pomp will be empty so switch B is on.
