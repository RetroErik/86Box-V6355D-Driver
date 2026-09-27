# COLORBAR comparison for the 86Box Yamaha V6355D

Two DOS programs that isolate the hidden-mode control bit in a V6355D test.

By **Retro Erik** — [Research repository](https://github.com/RetroErik/86Box-V6355D-Driver) · [YouTube](https://www.youtube.com/@RetroErik)

## Overview

Derived from Retro Erik's PC1 `colorbar.asm` by changing the framebuffer
segment to `B800h` and making the mode-control byte selectable at assembly
time. Source and binaries retain the license in [LICENSE](LICENSE).

These two DOS programs are built from the PC1 `colorbar.asm`, with the
framebuffer changed from `B000h` to the standalone 86Box card's `B800h`.
The original PC1 source and COM file are unchanged. Both tests require a
V20, 286, or newer CPU because COLORBAR contains 80186 instructions.

| File | Write to mode port `0x3D8` | Purpose |
| --- | --- | --- |
| `CB86H.COM` | `0x4A` | Requests hidden 160×200×16 mode |
| `CB86C.COM` | `0x0A` | CGA control with bit 6 cleared |

## Running the comparison

Use the same Generic XT Clone with a V20 and Yamaha V6355D for both runs.
Choose **True colour** if testing the programmable palette. Run one program,
press ESC to restore text mode, then run the other. On the unpatched 86Box
driver, both programs were tested and showed the same vertical striped CGA
interpretation. This confirms that the `B800h` framebuffer is reached while
bit 6 of the mode register is ignored by the renderer. With the experimental
patch, `CB86H.COM` is expected to show 16 broad bars and `CB86C.COM` to keep
the stripes. The author of COLORBAR manually ran both programs in the separate
patched 86Box build: `CB86H.COM` showed the exact expected image and colors,
and `CB86C.COM` showed CGA colors. ESC worked as expected. `CGACAL.EXE` also
showed all 16 colors correctly. These are user observations, without an
assistant-captured screenshot. The [author-provided screenshot](../../Screenshots/Skjermbilde%202026-09-27%20192932.png)
is from the patched test build with V20 at 16 MHz and 640 KB RAM.

## Rebuilding with NASM

```powershell
nasm -f bin -D V6355_MODE=0x4A colorbar-86box.asm -o CB86H.COM
nasm -f bin -D V6355_MODE=0x0A colorbar-86box.asm -o CB86C.COM
```

On 27 September 2026, both included `.COM` files were rebuilt with NASM and
matched the rebuilt files byte for byte (SHA-256 comparison).

## License

The source and both DOS binaries retain the [CC BY-NC 4.0 license](LICENSE)
of the original [PC1 COLORBAR project](https://github.com/RetroErik/Olivetti-PC1-Hidden-graphics-mode).
They are test programs, separate from the GPLv2 86Box executable.
Both this directory's `LICENSE` and the [repository-level license](../../LICENSE)
contain the official CC BY-NC 4.0 legal text.
