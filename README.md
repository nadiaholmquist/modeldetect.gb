# modeldetect.gb

A relatively simple program that detects which model of Game Boy it's running on and prints the initial values of the registers that were used to determine this.

## Building
RGBDS is needed to build, make sure its tools are in `$PATH` and run `make`.

## Usage
Two ROMs will be built, a `.gb` and a `.gbc`, only difference between them is the GBC compatible flag being set in the ROM header. The color-incompatible one can be used to test the DMG compatible mode on the GBC/GBA, which has different initial register values from the color-compatible mode.

If you see red text, this means your emulator is not locking out accesses to the GBC palettes when it's supposed to.
