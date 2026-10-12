# omacursor

An Omarchy shell plugin that recolors your system cursor to the active
Omarchy theme automatically: accent border, background interior. Click the
bar icon to swap it to accent fill.

![omacursor preview](preview.png)

## Install

```bash
omarchy plugin add https://github.com/berrimi/omacursor.git --enable --yes
```

The icon lands on the right side of the bar.

## Use it

- **Left-click the icon:** swap between normal and accent-fill cursor.
- **Hover the icon:** the tooltip tells you which mode is active.

The choice persists across shell and system restarts (in
`~/.local/state/omacursor/settings.toml`). If you ever want out:

```bash
./scripts/theme-cursor.py restore
omarchy plugin disable io.github.berrimi.omacursor
```

## Files

- `Service.qml` — watches the Omarchy palette and reapplies the cursor theme.
- `BarWidget.qml` — the bar icon and click-to-swap toggle.
- `assets/cursor.svg` — the bar icon (white silhouette; the bar tints it).
- `scripts/theme-cursor.py` — builds and applies a temporary recolored
  Xcursor theme. `apply-omarchy` reads the current Omarchy colors,
  `restore` returns to the previous cursor theme and size. Both toggle
  variants stay built on disk, so switching is instant after the first
  build of each.

## Credits

The cursor theming engine (`scripts/theme-cursor.py`) is derived from
[Big Cheese](https://github.com/OldJobobo/big-cheese) by J. S. Brown
(OldJobobo), MIT licensed.

## License

MIT — see [LICENSE](LICENSE).
