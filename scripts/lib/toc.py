"""Find and read the addon's .toc files."""
import re
from pathlib import Path

from lib import log

ADDON = "LuaPad"
SRC = Path("src")


def discover(folder=SRC):
    """The primary .toc first, then flavor .toc files (LuaPad_*.toc), as file names."""
    folder = Path(folder)
    if not (folder / f"{ADDON}.toc").is_file():
        log.fail(f"Missing primary TOC '{folder / f'{ADDON}.toc'}'.")
    return [f"{ADDON}.toc"] + sorted(p.name for p in folder.glob(f"{ADDON}_*.toc"))


def field(path, name):
    match = re.search(rf"^## {re.escape(name)}:[ \t]*(.*)$", Path(path).read_text(encoding="utf-8"), re.M)
    return match.group(1).strip() if match else ""


def interfaces(path):
    value = field(path, "Interface")
    if not value:
        log.fail(f"Could not read ## Interface: from '{path}'.")
    return [part for part in re.sub(r"\s", "", value).split(",") if part]


def lua_files(path):
    lines = Path(path).read_text(encoding="utf-8").splitlines()
    return sorted(line for line in lines if re.match(r"^[A-Za-z0-9_].*\.lua$", line))


def set_version(path, version):
    text = Path(path).read_text(encoding="utf-8")
    text, count = re.subn(r"^## Version: .*$", f"## Version: {version}", text, flags=re.M)
    if not count:
        log.fail(f"Could not update ## Version: in '{path}'.")
    Path(path).write_text(text, encoding="utf-8")
