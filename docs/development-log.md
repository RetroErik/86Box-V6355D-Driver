# Development log

By **Retro Erik** — [Research repository](https://github.com/RetroErik/86Box-V6355D-Driver) · [YouTube](https://www.youtube.com/@RetroErik)

## 27 September 2026 — upstream pull request

- Fetched the latest 86Box `master` (`bfcf8558a18ec893ee29693ac02d369909c04e91`) and created branch `v6355d-160x200x16`. The upstream change since the experimental patch base was unrelated to the V6355D source.
- Built the branch with MSYS2 UCRT64, CMake, and Ninja. The incremental build completed successfully, including the 86Box executable link. `git diff --check` passed.
- Created the separate [RetroErik/86Box fork](https://github.com/RetroErik/86Box), committed the single-file change as [`f2240360`](https://github.com/RetroErik/86Box/commit/f2240360ebc17a9c521ce2ec80e58354fbea1fe1), and opened [86Box PR #8135](https://github.com/86Box/86Box/pull/8135). The PR diff contains only `src/video/vid_cga_v6355.c`.
- The PR describes the author-confirmed 160×200×16 image and the CGA/DOS controls. The 192- and 204-line settings, 512-dot output width, other CRTC settings, and other output types remain untested in 86Box. In particular, the hardware-confirmed 192-line setting is a priority for later testing, not a verified PR result.

## 27 September 2026 — first 86Box graphics milestone

- Compared `CB86H.COM` (`0x3D8 = 0x4A`) with `CB86C.COM` (`0x3D8 = 0x0A`) in the unpatched 86Box Yamaha V6355D device. Both produced the ordinary CGA interpretation.
- Added a packed 4-bit, CGA-interlaced 160×200×16 renderer in `src/video/vid_cga_v6355.c`. The experimental patch is based on 86Box commit `6a83ed30e5d776e6e87e53fec68eaa06144930a7`.
- Built a separate Windows test version of 86Box. The installed emulator executable was left untouched.
- Rebuilt the driver after the final comment and formatting edits; the incremental build completed without warnings. The experimental patch passed `git diff --check` and `git apply --cached --check` against the upstream index.
- Rebuilt `CB86H.COM` and `CB86C.COM` from the published NASM source and confirmed byte-for-byte SHA-256 matches with the included binaries.
- In the patched build, the COLORBAR author confirmed the `CB86H.COM` image and colors as correct. ESC worked, `CB86C.COM` showed CGA colors, and `CGACAL.EXE` showed all 16 colors.
- The [test screenshot](../Screenshots/Skjermbilde%202026-09-27%20192932.png) is from the patched build with Generic XT, V20 at 16 MHz, 640 KB RAM, Yamaha V6355D, and True colour output.
- During the publication review, fixed the new mode's reported resolution and color depth (`width / 4`, 4 bits per pixel). A source-level bounds review covered the 640- and 512-pixel output widths, and the driver rebuilt without warnings. No new visual emulator test was run for the 512-pixel setting.

These results verify the static test image in that configuration. Palette protocol, other monitor modes, CRTC edge cases, and full ACV-1030/PC1 equivalence remain open for study.

## Sources and scope

See [compatibility notes](compatibility.md), the [original PC1 project](https://github.com/RetroErik/Olivetti-PC1-Hidden-graphics-mode), [John Elliott’s ACV-1030 manual transcription](https://www.seasip.info/VintagePC/acv1030.html), and the [86Box V6355D source](https://github.com/86Box/86Box/blob/master/src/video/vid_cga_v6355.c).
