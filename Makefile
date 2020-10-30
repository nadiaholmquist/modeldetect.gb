ASM = rgbasm
LINK = rgblink
GFX = rgbgfx
FIX = rgbfix

ROM = modeldetect.gb

FIX_FLAGS = -v -p 0 -s -l 0x33
FIX_FLAGS_GBC = -v -p 0 -C

SOURCES = $(wildcard src/*)
GRAPHICS = $(wildcard gfx/*.?bpp.png)

INCLUDE = -iinc/ -iout/gfx
OBJDIR = out
DIRS = $(OBJDIR)/src $(OBJDIR)/gfx
OBJECTS = $(addprefix out/, $(SOURCES:.asm=.o))
GFXOBJECTS = $(addprefix out/, $(GRAPHICS:.png=))
MAP = $(ROM:.gb=.map)
SYM = $(ROM:.gb=.sym)

all: $(ROM) $(ROM)c

$(OBJDIR)/%.o: %.asm
	@$(ASM) $(INCLUDE) -o $@ $<
	@echo "  ASM	$@"

$(OBJDIR)/%.1bpp: %.1bpp.png
	@$(GFX) -d 1 -o $@ $<
	@echo "  GFX	$@"

$(OBJDIR)/%.2bpp: %.2bpp.png
	@$(GFX) -d 2 -o $@ $<
	@echo "  GFX	$@"

$(OBJECTS): $(GFXOBJECTS)

$(ROM): $(OBJECTS)
	@$(LINK) -o $@ -n $(SYM) -m $(MAP) $^
	@$(FIX) $(FIX_FLAGS) $@
	@echo "  LINK	$@"

$(ROM)c: $(OBJECTS)
	@$(LINK) -o $@ -n $(SYM) -m $(MAP) $^
	@$(FIX) $(FIX_FLAGS_GBC) $@
	@echo "  LINK	$@"

clean:
	rm -rf $(ROM) $(ROM)c $(MAP) $(SYM) $(OBJDIR)

$(shell mkdir -p $(DIRS))
