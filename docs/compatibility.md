# Compatibility notes

By **Retro Erik** — [Research repository](https://github.com/RetroErik/86Box-V6355D-Driver) · [YouTube](https://www.youtube.com/@RetroErik)

| Item | PC1 onboard V6355D | ACV-1030 card | Installed, unpatched 86Box V6355D | Patched test build |
| --- | --- | --- | --- | --- |
| Hidden-mode control | `0x3D8 = 0x4A` | `0x3D8 = 0x4A` after card initialization | Bit 6 ignored by renderer | `CB86H.COM` image and colors confirmed by its author |
| CGA controls | Ordinary CGA-compatible output | Ordinary CGA-compatible output | `CB86C.COM` and `CGACAL.EXE` work | User reports CGA colors in `CB86C.COM` and all 16 colors in `CGACAL.EXE` |
| Register and palette ports | Full `0x3DD/0x3DE`; short aliases also work on PC1 | Full `0x3DD/0x3DE` required by hardware tests | Full `0x3DD/0x3DE` decoded | Unchanged from upstream |
| 16 KB video RAM | `B000h` and mirrors on real PC1 | `B800h` documented; both `B000h` and `B800h` worked in local tests | Maps `B8000-BFFFF`, wrapping through 16 KB | Same mapping; `CB86H.COM` uses `B800h` |
| Programmable colors | Analog RGB output | NTSC composite output; CGA/TTL is fixed IRGB | `True colour` display option, with incomplete hardware protocol | Correct COLORBAR colors in `True colour`; output equivalence untested |
| CPU | NEC V40 | PC/XT/AT host | Host machine's configured CPU | Generic XT with NEC V20 at 16 MHz, 640 KB RAM in the confirmed screenshot |

The [PC1 source](https://github.com/RetroErik/Olivetti-PC1-Hidden-graphics-mode/blob/main/colorbar.asm)
uses 80186-compatible shift instructions. A generic 8088 is therefore not a
valid host for that exact binary. Use a V20 or 286 for the comparison tests.

The unpatched source contains renderers for text, CGA 320×200×4, and
CGA 640×200×2, plus a TODO for 160×200×16. The patched build adds that
renderer. The configuration dialog's
`RGB`, `Composite`, and `True colour` selections alter output processing;
they do not add hidden-mode rendering.

In an unpatched baseline test with a Generic XT/V20, Yamaha V6355D, and True colour,
`CB86C.COM` (`0x0A`) and `CB86H.COM` (`0x4A`) produced the same vertical
striped CGA image. Both use `B800h`; their only binary difference is the
mode-control byte. This is the baseline for the experimental patch. In the
patched build, the author of COLORBAR confirmed the `CB86H.COM` image and
colors as correct. The user also reported that ESC exits as expected,
`CB86C.COM` displays CGA colors, and `CGACAL.EXE` displays all 16 colors
correctly. The [patched-build screenshot](../Screenshots/Skjermbilde%202026-09-27%20192932.png)
shows a V20 at 16 MHz with 640 KB RAM. These observations cover this Generic XT/V20/True colour setup;
other card profiles and output types have not been tested.

Sources: [86Box V6355 device](https://github.com/86Box/86Box/blob/master/src/video/vid_cga_v6355.c),
[ACV-1030 manual transcription](https://www.seasip.info/VintagePC/acv1030.html),
and local PC1/ACV-1030 hardware-test notes.
