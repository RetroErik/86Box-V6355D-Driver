## Summary

Add packed 160×200×16 rendering to the existing Yamaha V6355D video device. In low-resolution graphics mode, bit 6 of the mode-control value written to port `0x3D8` selects the new renderer; the existing CGA 320×200×4 path remains selected when the bit is clear. The renderer uses the same CRTC memory address and odd/even scanline bank selection as the existing 320-pixel path. Each 16-bit VRAM fetch supplies four high-to-low 4-bit pixel indices; each index is repeated four times in the current output buffer and passed through the existing palette/output processing.

This PR changes only `src/video/vid_cga_v6355.c`. It adds no ROM, asset, or dependency. It does not claim support for the 640×200×16 mode or complete PC1/ACV-1030 emulation.

The mode metadata reports `width / 4` logical pixels and 4 bits per pixel. The existing CGA mode metadata remains unchanged.

## Verification

- Built the patched 86Box source on Windows with MSYS2 UCRT64, CMake, Ninja, GCC, and Qt 5. The changed V6355D source produced no new compiler warnings.
- In a separate 86Box test build configured as Generic XT, NEC V20 at 16 MHz, 640 KB RAM, Yamaha V6355D, and True colour output, the author of the COLORBAR diagnostic confirmed that `CB86H.COM` (`0x3D8 = 0x4A`) displays the expected image and colors.
- `CB86C.COM` (`0x3D8 = 0x0A`) showed CGA colors, `CGACAL.EXE` showed all 16 colors, and ESC returned to DOS.
- The unpatched 86Box baseline rendered `CB86H.COM` and `CB86C.COM` identically as ordinary CGA graphics.
- Both DOS comparison binaries were rebuilt from the linked NASM source and matched the published binaries byte for byte.
- Source-level bounds review: the renderer writes at most 640 entries in the 640-entry line buffer. Both bytes of each word stay within one of the 8 KB CGA banks of the 16 KB VRAM. The mode metadata change rebuilt without warnings.

Only the 160×200×16 image in the configuration above has been visually verified. The 192- and 204-line settings, the 512-dot output width, additional CRTC settings, other output types, and timing behavior have not been tested with this change in 86Box.

## Checklist

* [ ] Closes an existing issue (add the issue number if applicable)
* [x] I have tested my changes locally and validated that the described functionality works as intended
* [ ] I have discussed this with core contributors already
* [ ] This pull request requires changes to the ROM set
* [ ] This pull request requires changes to the asset set
* [ ] This pull request adds, changes or removes an external dependency

## References

- [ACV-1030 manual transcription](https://www.seasip.info/VintagePC/acv1030.html), especially the display mode control register.
- [Research repository, test programs, compatibility notes, and screenshot](https://github.com/RetroErik/86Box-V6355D-Driver).
- [Retro Erik’s PC1 hidden-mode project](https://github.com/RetroErik/Olivetti-PC1-Hidden-graphics-mode) and [YouTube channel](https://www.youtube.com/@RetroErik).

## Development disclosure

This project was developed with AI-assisted tools (GitHub Copilot, Codex, and similar tools) in VS Code, including an exploratory “vibe coding” workflow. Final design decisions, testing, verification, and hardware comparisons were performed by the project author. The author has reviewed the change and is available to address maintainer feedback.
