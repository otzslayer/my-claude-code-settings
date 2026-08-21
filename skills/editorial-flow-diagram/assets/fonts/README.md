# Fonts

Put the **Pretendard** font files here so the exported PNG renders in Pretendard.
`scripts/render_png.py` auto-installs every `.ttf` / `.otf` / `.ttc` in this
folder (into the user fonts dir + `fc-cache`) before rasterizing.

Recommended files (weight 600 is used for titles and terminators):

- `Pretendard-Regular.otf` (or `.ttf`)
- `Pretendard-SemiBold.otf` (or `.ttf`)

A variable font (`PretendardVariable.ttf`) covering weight 600 also works.

Pretendard is open source under the SIL Open Font License 1.1
(https://github.com/orioncactus/pretendard). Download the release, then copy the
Regular and SemiBold files into this folder.

If this folder has no font files, rendering still works — it falls back to the
next available font in the family list (Apple SD Gothic Neo / Noto Sans KR /
Malgun Gothic / Helvetica / Arial).
