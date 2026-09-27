# Upstream pull request review

By **Retro Erik** — [Research repository](https://github.com/RetroErik/86Box-V6355D-Driver) · [YouTube](https://www.youtube.com/@RetroErik)

## Assessment, 27 September 2026

The one-file renderer patch has a successful Windows build and a positive author-verified visual test. It was submitted as [86Box PR #8135](https://github.com/86Box/86Box/pull/8135) from the separate [RetroErik/86Box fork](https://github.com/RetroErik/86Box), branch `v6355d-160x200x16`, commit `f2240360ebc17a9c521ce2ec80e58354fbea1fe1`. The PR is open for maintainer review; it has not been merged. Only 160×200×16 has been visually verified in 86Box.

The source review found and fixed a mode-metadata omission: the new 16-color path now reports `width / 4` logical pixels and 4 bits per pixel. The 640/512 output-width settings make the renderer iterate over 40/32 VRAM words, writing 16 output entries per word, so the largest written pixel index is 639/511 within the 640-entry line buffer. The two fetched bytes stay inside the selected 8 KB VRAM bank, including when the CRTC memory address wraps. This is a source-level bounds check, not a visual 512-width test.

## Follow-up verification and review

1. Compare the implementation with the [ACV-1030 mode-control description](https://www.seasip.info/VintagePC/acv1030.html) and the PC1 hardware observations. Explain the packed-nibble order, CGA line banking, memory-address progression, and bit-6 selection if maintainers request more evidence.
2. Add reproducible tests for mode switching and CRTC start-address behavior. Prioritize the hardware-confirmed 192-line PC1 setting in a later, separate test task. Test the 512-dot output-width setting if it is intended to be supported. Report each result separately; the current PR claims only the 160×200×16 visual result.
3. Rebuild and review the diff after any further source edits. The submitted revision built successfully, passed `git diff --check`, and contains only `src/video/vid_cga_v6355.c`.
4. Update the [PR description](pr-description.md) and live PR as results or maintainer discussion change. The discussion checkbox remains unchecked until discussion actually occurs.

The research repo’s CC BY-NC DOS diagnostics and screenshot are evidence links; they should not be copied into the GPLv2 86Box PR. No new ROM, asset, or dependency is needed for this renderer change.

## Workflow used for the separate 86Box fork

The commands below record the contribution workflow, which is **already complete** through PR creation. Do not run them again in the current checkout. The patch was already present in the nested `86Box/` checkout and was not reapplied. `gh repo fork --clone=false --remote=true`, run from inside that checkout, made the fork `origin` and renamed `86Box/86Box` to `upstream`.

```powershell
cd .\86Box
gh auth status
git fetch origin master
git switch -c v6355d-160x200x16 origin/master
gh repo fork --clone=false --remote=true
git remote -v
git diff --check
git status --short
git add src/video/vid_cga_v6355.c
git diff --cached --name-only
git commit -m "video: add V6355D 160x200x16 rendering"
git push -u origin v6355d-160x200x16
gh pr create --repo 86Box/86Box --base master --head RetroErik:v6355d-160x200x16 --title "video: add Yamaha V6355D 160x200x16 rendering" --body-file ..\docs\pr-description.md
```

The staged and published PR file lists were exactly `src/video/vid_cga_v6355.c`. The branch was based on upstream commit `bfcf8558a18ec893ee29693ac02d369909c04e91`. The PR was opened for normal review with its untested cases explicitly listed. If repeating this workflow in a fresh clone, first inspect remotes and branch names because the fork and PR already exist.

## Research repository publication

The public [RetroErik/86Box-V6355D-Driver](https://github.com/RetroErik/86Box-V6355D-Driver) repository contains the curated research files. The nested 86Box clone, private `PROJECT_STATE.md`, test VHD, ROMs, DLLs, build output, and installed executable are excluded. The public [development log](development-log.md) preserves a shareable history without local disk paths.

The patch contains GPLv2-derived 86Box code; keep [COPYING-86BOX](../COPYING-86BOX) and upstream notices with it. Original research documentation and the author's rights in the screenshot use the repository's [CC BY-NC 4.0 license](../LICENSE), matching the PC1 project. Third-party elements in the screenshot retain their own terms. The DOS test source and binaries are also under [CC BY-NC 4.0](../tests/colorbar/LICENSE), separate from the emulator. The author approved the included test screenshot for public release on 27 September 2026.

From the root of this research checkout, the initial publication used the following workflow after reviewing `git status` and the staged file list:

```powershell
git remote -v
git add .gitattributes .gitignore COPYING-86BOX LICENSE README.md Screenshots docs patches tests
git diff --cached --name-only
git commit -m "docs: publish V6355D research and test project"
git push -u origin main
```

The local research checkout already has `origin` set to `https://github.com/RetroErik/86Box-V6355D-Driver.git`. `PROJECT_STATE.md` and the nested `86Box/` checkout are ignored.
