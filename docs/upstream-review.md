# Upstream pull request review

By **Retro Erik** — [Research repository](https://github.com/RetroErik/86Box-V6355D-Driver) · [YouTube](https://www.youtube.com/@RetroErik)

## Assessment, 27 September 2026

The one-file renderer patch has a successful Windows build and a positive author-verified visual test, so it is a credible **draft PR candidate**. It is not yet a finished upstream submission. The 86Box fork, feature branch, commit, and PR have not been created. Maintainers must still be able to review the implementation and its supported scope against [86Box’s contribution requirements](https://github.com/86Box/86Box/blob/master/CONTRIBUTING.md).

## Before submitting upstream

1. Check the code against the [ACV-1030 mode-control description](https://www.seasip.info/VintagePC/acv1030.html) and the PC1 hardware observations; explain why the packed-nibble order, CGA line banking, memory-address progression, and bit-6 selection are correct. Visual output alone does not prove the emulation method.
2. Add a small reproducible test record for mode switching and CRTC start-address behavior. Test the 512-pixel output-width setting if it is intended to be supported. State what remains untested instead of claiming broad hardware equivalence.
3. Rebuild after the final source edit and check that `git diff --check` and `git apply --cached --check` pass. Confirm the PR diff contains only the intended source file.
4. Ensure the [PR description](pr-description.md) reflects the exact final test results and any maintainer discussion. Leave the discussion checkbox unchecked until discussion actually occurs.

The research repo’s CC BY-NC DOS diagnostics and screenshot are evidence links; they should not be copied into the GPLv2 86Box PR. No new ROM, asset, or dependency is needed for this renderer change.

## Exact workflow for the separate 86Box fork

Open PowerShell in the root of this research checkout, then run these commands **after** the review items are resolved. The patch is already present in the nested `86Box/` checkout; do not apply it again. `gh repo fork` changes its remotes so the fork becomes `origin` and `86Box/86Box` becomes `upstream`.

```powershell
cd .\86Box
gh auth status
gh repo fork 86Box/86Box --clone=false --remote=true
git remote -v
git switch -c v6355d-160x200x16
git diff --check
git status --short
git add src/video/vid_cga_v6355.c
git diff --cached --name-only
git commit -m "video: add V6355D 160x200x16 rendering"
git push -u origin v6355d-160x200x16
gh pr create --repo 86Box/86Box --base master --head RetroErik:v6355d-160x200x16 --title "video: add Yamaha V6355D 160x200x16 rendering" --body-file ..\docs\pr-description.md
```

The staged file list should be exactly `src/video/vid_cga_v6355.c`. If a fork already exists when the command is run, inspect the remotes before adding or renaming them. Use `--draft` with `gh pr create` while the remaining tests and upstream review are pending.

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
