# Yamaha V6355D 160×200×16 graphics in 86Box

Research, tests, and an experimental 86Box patch for the Yamaha V6355D hidden 16-color mode.

By **Retro Erik** — [YouTube: Retro Hardware and Software](https://www.youtube.com/@RetroErik)

![Project status](https://img.shields.io/badge/Status-experimental-orange)
![Platform](https://img.shields.io/badge/Platform-86Box-blue)
![Research license](https://img.shields.io/badge/Research%20license-CC%20BY--NC%204.0-green)

## Overview

86Box already includes a Yamaha V6355D video device. This project adds an experimental renderer for the packed 160×200×16 mode selected by bit 6 of port `0x3D8`. The first target is an ACV-1030-style ISA video card in a standard PC/XT or AT. A full Olivetti Prodest PC1 machine profile is a separate future project.

This is the **research repository**: [RetroErik/86Box-V6355D-Driver](https://github.com/RetroErik/86Box-V6355D-Driver). The eventual pull request to [86Box/86Box](https://github.com/86Box/86Box) should contain only the upstream source change and any tests accepted by its maintainers. Research notes, DOS binaries, screenshots, and experimental patches belong here.

| Item | Current result |
| --- | --- |
| 160×200×16 image | `CB86H.COM` image and colors confirmed by the COLORBAR author in a patched 86Box build |
| CGA control | `CB86C.COM` showed CGA colors; `CGACAL.EXE` showed all 16 colors |
| DOS return | ESC worked in the patched test |
| Build | Separate Windows build completed on 27 September 2026 |
| Scope | One renderer in `src/video/vid_cga_v6355.c`; no new ROM or dependency |

The confirmation above is from the author’s manual test. It does not establish support for every V6355D mode, output type, or timing behavior.

## Quick start

1. Build 86Box with the [experimental patch](patches/README.md) in a clean checkout, or use a build that already includes the source change. The patch is **already applied in the local `86Box/` checkout** and must not be applied there again.
2. Create a Generic XT with a NEC V20, Yamaha V6355D, and **True colour** display output. The verified screenshot used a V20 at 16 MHz and 640 KB RAM.
3. Put `CB86H.COM` and `CB86C.COM` from [tests/colorbar](tests/colorbar/README.md) on a DOS disk. Run each separately and press ESC to return to DOS.

| Program | Port `0x3D8` | Expected comparison |
| --- | --- | --- |
| `CB86H.COM` | `0x4A` | Packed 160×200×16 image in the patched build |
| `CB86C.COM` | `0x0A` | Ordinary CGA interpretation |

Both test programs write to `B800h`, the framebuffer of the standalone 86Box V6355D device. The original PC1 COLORBAR program writes to `B000h` and is therefore not a direct test of this 86Box card configuration. See [compatibility notes](docs/compatibility.md) for the hardware differences.

## Screenshot

<p>
<em>Patched 86Box test build, Generic XT with V20 at 16 MHz and 640 KB RAM, showing the COLORBAR test pattern. The author confirmed that the image and colors match the expected output.</em><br>
<img src="Screenshots/Skjermbilde%202026-09-27%20192932.png" width="70%" alt="Patched 86Box showing the V6355D COLORBAR test pattern">
</p>

## Repository contents

| Path | Contents |
| --- | --- |
| [tests/colorbar](tests/colorbar/README.md) | NASM source, two DOS `.COM` comparison programs, and their separate license |
| [docs/compatibility.md](docs/compatibility.md) | Confirmed and unconfirmed PC1, ACV-1030, and 86Box behavior |
| [docs/development-log.md](docs/development-log.md) | Public project history and test milestones |
| [docs/upstream-review.md](docs/upstream-review.md) | Upstream PR review, blockers, and the fork/branch workflow |
| [docs/pr-description.md](docs/pr-description.md) | Draft text for the proposed upstream pull request |
| [patches](patches/README.md) | Experimental patch and application notes |
| `Screenshots/` | Test evidence from the patched build |

The V6355D code is compiled into `86Box.exe`; there is no standalone driver DLL to copy into an installed 86Box folder. This repository does not distribute a patched executable, ROMs, or DOS disk images. The separate local test folder is not a public release package.

## Planned work

- Check the packed-pixel and CGA interleave behavior across more CRTC settings and line counts.
- Compare palette commands and RGB/composite output with real PC1 and ACV-1030 hardware.
- Document and implement card-specific mapping and port behavior before claiming PC1 or ACV-1030 compatibility beyond this mode.

## Development and provenance

This project was developed with AI-assisted tools (GitHub Copilot, Codex, and similar tools) in VS Code, including an exploratory “vibe coding” workflow. Final design decisions, testing, verification, and hardware comparisons were performed by the project author. The patch remains subject to normal 86Box code review and technical validation.

## Credits

- **Author and hardware testing:** Retro Erik. See the [original PC1 hidden-mode project](https://github.com/RetroErik/Olivetti-PC1-Hidden-graphics-mode) and [YouTube channel](https://www.youtube.com/@RetroErik).
- **86Box V6355D source:** John Elliott, Miran Grca, W. M. Martinez, and other 86Box contributors.
- **COLORBAR tests:** Derived from Retro Erik’s PC1 program. These DOS programs are separate from 86Box.

## License

The original research documentation and the author's rights in the provided screenshot are © 2026 Dag Erik Hagesæter (Retro Erik), licensed under [Creative Commons Attribution-NonCommercial 4.0 International](LICENSE), as in the [PC1 project](https://github.com/RetroErik/Olivetti-PC1-Hidden-graphics-mode). The included `LICENSE` is the official Creative Commons legal text.

| Material | License |
| --- | --- |
| Original research documentation and the author's rights in the screenshot | [CC BY-NC 4.0](LICENSE) |
| `tests/colorbar/` source and DOS binaries | [CC BY-NC 4.0](tests/colorbar/LICENSE) |
| 86Box-derived source patch in `patches/` | 86Box [GPLv2](COPYING-86BOX); preserve upstream notices |

The CC BY-NC grant does not relicense the GPLv2-derived patch. Third-party elements visible in the screenshot and external sources linked from the documentation retain their own terms.

## Contributing

Bug reports, reproducible test results, and hardware comparisons are welcome in the [research repository](https://github.com/RetroErik/86Box-V6355D-Driver). Code intended for upstream 86Box should follow its [contribution guidelines](https://github.com/86Box/86Box/blob/master/CONTRIBUTING.md).
