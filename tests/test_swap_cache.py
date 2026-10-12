"""Second apply of a color pair must hit the on-disk variant cache (no rebuild)."""

import json
import os
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "scripts" / "theme-cursor.py"
REAL_CURSOR = Path("/usr/share/icons/Adwaita/cursors/left_ptr")


def run(env, *args):
    completed = subprocess.run(
        ["python3", str(SCRIPT), *args],
        env=env, capture_output=True, text=True, timeout=120,
    )
    assert completed.returncode == 0, completed.stderr or completed.stdout
    return json.loads(completed.stdout)


def test_toggle_uses_cached_variants(tmp_path):
    icons = tmp_path / "icons" / "Adwaita" / "cursors"
    icons.mkdir(parents=True)
    shutil.copy2(REAL_CURSOR, icons / "left_ptr")
    fakebin = tmp_path / "bin"
    fakebin.mkdir()
    log = tmp_path / "hyprctl.log"
    (fakebin / "hyprctl").write_text(
        "#!/bin/sh\n"
        f'echo "$@" >> "{log}"\n'
        'if [ "$1" = -j ]; then echo \'{"x":1,"y":2}\'; fi\n'
    )
    (fakebin / "hyprctl").chmod(0o755)
    state = tmp_path / "state.json"
    env = dict(os.environ, PATH=f"{fakebin}{os.pathsep}{os.environ['PATH']}",
               OMACURSOR_HYPRCTL="hyprctl",
               OMACURSOR_ICON_ROOT=str(tmp_path / "icons"),
               OMACURSOR_RUNTIME_ICON_ROOT=str(tmp_path / "rticons"),
               OMACURSOR_CURSOR_STATE=str(state))

    normal = ("#78824b", "#222222")
    swapped = ("#222222", "#78824b")
    first = run(env, "apply", *normal, "default", "24")
    assert first["cached"] is False
    second = run(env, "apply", *swapped, "default", "24")
    assert second["cached"] is False
    # Both variants now built: toggling must not rebuild.
    back = run(env, "apply", *normal, "default", "24")
    assert back["cached"] is True
    assert (back["fill"], back["outline"]) == normal
    assert Path(back["themePath"]).is_dir()
    forth = run(env, "apply", *swapped, "default", "24")
    assert forth["cached"] is True
    assert Path(forth["themePath"]) != Path(back["themePath"])
    assert len(json.loads(state.read_text())["builds"]) == 2
    restored = run(env, "restore")
    assert restored["restored"] is True
    assert not state.exists()


def test_refresh_warps_to_bar_band_and_back(tmp_path):
    icons = tmp_path / "icons" / "Adwaita" / "cursors"
    icons.mkdir(parents=True)
    shutil.copy2(REAL_CURSOR, icons / "left_ptr")
    fakebin = tmp_path / "bin"
    fakebin.mkdir()
    log = tmp_path / "hyprctl.log"
    (fakebin / "hyprctl").write_text(
        "#!/bin/sh\n"
        f'echo "$@" >> "{log}"\n'
        'if [ "$1" = -j ]; then echo \'{"x":100,"y":50}\'; fi\n'
    )
    (fakebin / "hyprctl").chmod(0o755)
    env = dict(os.environ, PATH=f"{fakebin}{os.pathsep}{os.environ['PATH']}",
               OMACURSOR_HYPRCTL="hyprctl",
               OMACURSOR_ICON_ROOT=str(tmp_path / "icons"),
               OMACURSOR_RUNTIME_ICON_ROOT=str(tmp_path / "rticons"),
               OMACURSOR_CURSOR_STATE=str(tmp_path / "state.json"))
    run(env, "apply", "#78824b", "#222222", "default", "24")
    calls = log.read_text().splitlines()
    assert "dispatch hl.dsp.cursor.move({ x = 100, y = 13 })" in calls
    assert "dispatch hl.dsp.cursor.move({ x = 100, y = 50 })" in calls
    assert calls.index("dispatch hl.dsp.cursor.move({ x = 100, y = 13 })") < calls.index("dispatch hl.dsp.cursor.move({ x = 100, y = 50 })")
    assert [c for c in calls if c.startswith("dispatch movecursor")] == []
