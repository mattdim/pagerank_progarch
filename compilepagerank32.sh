nasm -g -f elf32 calcolaP1s.nasm
nasm -g -f elf32 calcolaP2s.nasm
nasm -g -f elf32 calcolaP1d.nasm
nasm -g -f elf32 calcolaP2d.nasm
nasm -g -f elf32 calcolaDeltaS.nasm
nasm -g -f elf32 pagerank32s.nasm
nasm -g -f elf32 calcolaRis.nasm
mv calcolaP1s.o calcolaP2s.o calcolaP1d.o calcolaP2d.o calcolaDeltaS.o pagerank32s.o calcolaRis.o ./bin/
gcc -g -O0 -m32 -msse ./bin/calcolaP1s.o ./bin/calcolaP2s.o ./bin/calcolaP1d.o ./bin/calcolaP2d.o ./bin/calcolaDeltaS.o ./bin/pagerank32s.o ./bin/calcolaRis.o pagerank32c.c -o ./bin/pagerank32c.exe -lm
