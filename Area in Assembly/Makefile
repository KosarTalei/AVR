main.out: main.c area.o
	gcc -o main.out -m32 main.c area.o
area.o: area.asm
	nasm -f elf area.asm