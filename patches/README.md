# Experimental 86Box V6355D patch

Source patch and application notes for the Yamaha V6355D 160×200×16 renderer.

By **Retro Erik** — [Research repository](https://github.com/RetroErik/86Box-V6355D-Driver) · [YouTube](https://www.youtube.com/@RetroErik)

## Overview

`0001-v6355d-160x200x16.patch` targets 86Box commit
`6a83ed30e5d776e6e87e53fec68eaa06144930a7` and modifies only
`src/video/vid_cga_v6355.c`. It adds the 160×200×16 packed-nibble renderer
and selects it with bit 6 of port `0x3D8` in low-resolution graphics mode.
It also reports the logical resolution and 4-bit color depth for this mode.
Ordinary CGA text and graphics paths remain in place.
The same source change was submitted separately as [86Box PR #8135](https://github.com/86Box/86Box/pull/8135).

## Applying the patch

The patch is **already present** in the local `86Box/` checkout. Do not apply
it there again. In a separate, clean checkout of that commit, run:

```powershell
git apply --check path/to/0001-v6355d-160x200x16.patch
git apply path/to/0001-v6355d-160x200x16.patch
```

Then build 86Box using its [build instructions](https://86box.readthedocs.io/en/latest/dev/buildguide.html). Select a Generic XT with a
V20 CPU and Yamaha V6355D display type **True colour**. `CB86H.COM` should
now show the 16-color test pattern; `CB86C.COM` should retain ordinary CGA colors.
The COLORBAR author confirmed the `CB86H.COM` image and colors in the separate
patched test build. The same user reported that `CB86C.COM` shows CGA colors,
`CGACAL.EXE` shows all 16 colors correctly, and ESC works as expected.

## Verification and limits

The patch has passed `git apply --cached --check` against the unmodified
upstream index and `git diff --check`. A separate Windows build succeeded on
27 September 2026. See the public [development log](../docs/development-log.md)
for the test scope and remaining hardware differences in
[compatibility notes](../docs/compatibility.md). The
verified screenshot used a V20 at 16 MHz, 640 KB RAM, and True colour output.
Only 160×200×16 was visually verified. The 192-line setting is a priority for
later testing; it, other CRTC settings, output types, and modes remain unverified
in 86Box.

The older patch sketch in `86Box-V6355D-hidden-mode-patch` uses `@@ -XXX`
hunk headers and must not be presented as a working patch.

## License

This patch modifies 86Box GPLv2 source. See [COPYING-86BOX](../COPYING-86BOX)
and preserve the original source notices. The separate DOS tests have their own
[license](../tests/colorbar/LICENSE). The original research prose in this README
uses the repository's [CC BY-NC 4.0 license](../LICENSE).
