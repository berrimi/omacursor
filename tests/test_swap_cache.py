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


def make_env(tmp_path):
    icons = tmp_path / "icons" / "Adwaita" / "cursors"
    icons.mkdir(parents=True)
    shutil.copy2(REAL_CURSOR, icons / "left_ptr")
    fakebin = tmp_path / "bin"
    fakebin.mkdir()
    log = tmp_path / "hyprctl.log"
    (fakebin / "hyprctl").write_text(
        "#!/bin/sh\n"
        f'echo "$@" >> "{log}"\n'
        'if [ "$1" = "-j" ] && [ "$2" = "cursorpos" ]; then echo \'{"x":1,"y":2}\'; fi\n'
        'if [ "$1" = "-j" ] && [ "$2" = "getoption" ]; then echo \'{"option":"cursor:invisible","bool":false}\'; fi\n'
    )
    (fakebin / "hyprctl").chmod(0o755)
    state = tmp_path / "state.json"
    env = dict(os.environ, PATH=f"{fakebin}{os.pathsep}{os.environ['PATH']}",
               OMACURSOR_HYPRCTL="hyprctl",
               OMACURSOR_ICON_ROOT=str(tmp_path / "icons"),
               OMACURSOR_RUNTIME_ICON_ROOT=str(tmp_path / "rticons"),
               OMACURSOR_CURSOR_STATE=str(state))
    return env, log, state


def test_toggle_uses_cached_variants(tmp_path):
    env, log, state = make_env(tmp_path)

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


def test_refresh_toggles_invisible(tmp_path):
    env, log, _ = make_env(tmp_path)
    run(env, "apply", "#78824b", "#222222", "default", "24")
    calls = log.read_text().splitlines()
    hide = "eval hl.config { cursor = { invisible = true } }"
    show = "eval hl.config { cursor = { invisible = false } }"
    move = "dispatch hl.dsp.cursor.move({ x = 1, y = 2 })"
    assert hide in calls
    assert show in calls
    assert move in calls
    assert calls.index(hide) < calls.index(show) < calls.index(move)
    assert [c for c in calls if c.startswith("dispatch movecursor")] == []


def test_repeat_apply_skips_hyprctl(tmp_path):
    env, log, _ = make_env(tmp_path)
    first = run(env, "apply", "#78824b", "#222222", "default", "24")
    assert first["cached"] is False
    second = run(env, "apply", "#78824b", "#222222", "default", "24")
    assert second["cached"] is True
    assert sum(1 for c in log.read_text().splitlines() if c.startswith("setcursor")) == 1
