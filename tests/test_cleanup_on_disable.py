"""cleanup-on-disable.sh restores the stock cursor only when truly unloaded."""

import json
import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPT = ROOT / "scripts" / "cleanup-on-disable.sh"
PLUGIN_ID = "io.github.berrimi.omacursor"


def setup_env(tmp_path, *, plugin_dir=True, layout_ids=None, plugins_ids=None):
    home = tmp_path / "home"
    plugindir = home / ".config" / "omarchy" / "plugins" / PLUGIN_ID
    if plugin_dir:
        plugindir.mkdir(parents=True)
    shell_json = home / ".config" / "omarchy" / "shell.json"
    shell_json.parent.mkdir(parents=True, exist_ok=True)
    shell_json.write_text(json.dumps({
        "plugins": [{"id": i} for i in (plugins_ids if plugins_ids is not None else [PLUGIN_ID])],
        "bar": {"layout": {"right": [{"id": i} for i in (layout_ids if layout_ids is not None else [PLUGIN_ID])]}},
    }))
    run = tmp_path / "run"
    (run / "omacursor").mkdir(parents=True)
    (run / "omacursor" / "cursor-theme.json").write_text(
        json.dumps({"baselineTheme": "quux", "baselineSize": 48}))
    icons = home / ".local" / "share" / "icons" / "omacursor-runtime"
    icons.mkdir(parents=True)
    (icons / "sentinel").write_text("x")
    fakebin = tmp_path / "bin"
    fakebin.mkdir()
    log = tmp_path / "hyprctl.log"
    (fakebin / "hyprctl").write_text(
        f'#!/bin/sh\necho "$@" >> "{log}"\n'
        'if [ "$1" = -j ]; then echo \'{"x":100,"y":50}\'; fi\n'
    )
    (fakebin / "hyprctl").chmod(0o755)
    env = dict(os.environ, HOME=str(home), XDG_RUNTIME_DIR=str(run),
               PATH=f"{fakebin}{os.pathsep}/usr/bin:/bin")
    return env, log, run, icons


def run_script(env):
    completed = subprocess.run(["sh", str(SCRIPT)], env=env,
                               capture_output=True, text=True, timeout=30)
    assert completed.returncode == 0, completed.stderr
    return completed


def test_enabled_plugin_is_left_alone(tmp_path):
    env, log, run, icons = setup_env(tmp_path)
    run_script(env)
    assert not log.exists()
    assert icons.is_dir()
    assert (run / "omacursor" / "cursor-theme.json").is_file()


def test_disabled_plugin_restores_baseline(tmp_path):
    # disable drops the bar entry but leaves a stale plugins[] entry: the
    # service must still treat that as unwanted.
    env, log, run, icons = setup_env(tmp_path, plugins_ids=[PLUGIN_ID], layout_ids=["something.else"])
    run_script(env)
    calls = log.read_text().splitlines()
    assert "setcursor quux 48" in calls
    assert "dispatch hl.dsp.cursor.move({ x = 100, y = 13 })" in calls
    assert "dispatch hl.dsp.cursor.move({ x = 100, y = 50 })" in calls
    assert not icons.exists()
    assert not (run / "omacursor").exists()


def test_removed_plugin_restores_baseline(tmp_path):
    env, log, run, icons = setup_env(tmp_path, plugin_dir=False, layout_ids=[], plugins_ids=[])
    run_script(env)
    calls = log.read_text().splitlines()
    assert "setcursor quux 48" in calls
    assert "dispatch hl.dsp.cursor.move({ x = 100, y = 13 })" in calls
    assert not icons.exists()
    assert not (run / "omacursor").exists()


def check(env):
    completed = subprocess.run(["sh", str(SCRIPT), "--check"], env=env,
                               capture_output=True, text=True, timeout=30)
    return completed.returncode


def test_check_passes_while_listed(tmp_path):
    env, log, run, icons = setup_env(tmp_path)
    assert check(env) == 0
    assert not log.exists()


def test_check_fails_once_unlisted(tmp_path):
    env, log, run, icons = setup_env(tmp_path, plugins_ids=[PLUGIN_ID], layout_ids=[])
    assert check(env) == 1
    assert not log.exists()
    assert icons.is_dir()
