ifeq ($(OS),Windows_NT)
    FTEQCC ?= fteqcc64.exe
    RM_CMD = del /Q
else
    FTEQCC ?= fteqcc64
    RM_CMD = rm -f
endif

all:
	$(FTEQCC) ./ssqc/progs.src
	$(FTEQCC) ./csqc/csprogs.src
	$(FTEQCC) ./menu/menu.src

clean:
	$(RM_CMD) qwprogs.dat csprogs.dat menu.dat qwprogs.lno csprogs.lno menu.lno files.dat progdefs.h
