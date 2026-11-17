#!/usr/bin/env python3
"""Upload the addon zip to CurseForge. Usage: curseforge-upload.py <archive_path> <notes_path> <version> (needs CF_API_TOKEN, CF_PROJECT_ID)"""
import json
import os
import sys
import urllib.error
import urllib.request
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lib import log  # noqa: E402
from lib import toc  # noqa: E402

API = "https://wow.curseforge.com/api"


fail = log.fail


def request(url, token, body=None, content_type=None):
    req = urllib.request.Request(url, data=body, headers={"X-Api-Token": token})
    if content_type:
        req.add_header("Content-Type", content_type)
    try:
        with urllib.request.urlopen(req) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        fail(f"CurseForge returned HTTP {error.code} for {url}\n{error.read().decode(errors='replace')}")


def existing_file(project, token, version):
    """The name of a file on CurseForge already called <version>, or None. Warns and returns None when it can't check."""
    try:
        with urllib.request.urlopen(urllib.request.Request(f"{API}/projects/{project}/files", headers={"X-Api-Token": token})) as response:
            data = json.load(response)
    except (urllib.error.URLError, ValueError) as error:
        log.warn("CurseForge duplicate check skipped", f"Could not list the project's files ({error}); uploading anyway.")
        return None
    files = data if isinstance(data, list) else data.get("data") or data.get("files") or []
    for item in files:
        names = {str(item.get(key, "")) for key in ("displayName", "display_name", "name", "fileName", "filename")}
        if version in names or any(name.endswith(f"-{version}.zip") for name in names):
            return next(name for name in names if name)
    return None


def main():
    if len(sys.argv) != 4:
        fail("Usage: curseforge-upload.py <archive_path> <notes_path> <version>")
    archive, notes, version = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
    token, project = os.environ.get("CF_API_TOKEN"), os.environ.get("CF_PROJECT_ID")
    if not project:
        fail("CF_PROJECT_ID is required.")
    if not token:
        fail("CF_API_TOKEN is required.")
    for path in (archive, notes):
        if not path.is_file():
            fail(f"File not found: {path}")

    tocs = toc.discover()
    interfaces = list(dict.fromkeys(i for name in tocs for i in toc.interfaces(toc.SRC / name)))
    log.info(f"Using interface versions from {len(tocs)} TOC file(s): {','.join(interfaces)}")

    duplicate = existing_file(project, token, version)
    if duplicate:
        log.warn("Already on CurseForge", f"A file named '{duplicate}' already exists for version {version}; not uploading it again.")
        return

    by_api = {str(v["apiVersion"]): v["id"] for v in request(f"{API}/game/versions", token) if v.get("apiVersion") is not None}
    missing = [i for i in interfaces if i not in by_api]
    if missing:
        fail("No CurseForge game versions for Interface values: " + ", ".join(missing))

    metadata = json.dumps({
        "changelog": notes.read_text(encoding="utf-8"),
        "changelogType": "markdown",
        "displayName": version,
        "gameVersions": [by_api[i] for i in interfaces],
        "releaseType": "release",
    })
    boundary = uuid.uuid4().hex
    body = (
        f'--{boundary}\r\nContent-Disposition: form-data; name="metadata"\r\nContent-Type: application/json\r\n\r\n{metadata}\r\n'
        f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{archive.name}"\r\n'
        "Content-Type: application/zip\r\n\r\n"
    ).encode() + archive.read_bytes() + f"\r\n--{boundary}--\r\n".encode()
    result = request(f"{API}/projects/{project}/upload-file", token, body, f"multipart/form-data; boundary={boundary}")
    if result.get("id") is None:
        fail("Upload response missing file id.")
    log.passed(f"Uploaded '{archive}' as CurseForge file id {result['id']} (version {version}).")


if __name__ == "__main__":
    main()
