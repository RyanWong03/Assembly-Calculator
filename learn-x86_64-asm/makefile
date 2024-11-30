math.o: math.asm
	nasm -f elf64 -o math.o math.asm

debug: math.asm
	nasm -f elf64 -g -F dwarf math.asm
	ld -o math math.o

math: math.o
	ld -o math math.o

.PHONY: clean
clean:
	rm -rf *~ *.o math
