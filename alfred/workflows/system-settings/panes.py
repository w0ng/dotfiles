"""Emit macOS System Settings, pane by pane and setting by setting, for Alfred.

Every list here is read at runtime, which is the whole design. A transcribed one
goes stale the next time Apple renames something, and the renamed pane stops
appearing with no error. Two files macOS and Alfred already ship supply
everything:

  * Alfred's own per-release catalogue, inside its framework, names the panes
    and localises them. Using it is what makes these results match the ones
    Alfred shows with System Settings ticked in Default Results, rather than
    merely resemble them.
  * Apple's .searchTerms files, beside each pane, list the individual settings
    and their alternate spellings. That is the index System Settings' own search
    box reads, so searching here finds what searching there finds.

A .searchTerms group key doubles as a deep link: used as ?anchor it navigates
System Settings to the control itself. Alfred's catalogue writes its own anchors
after * instead, which System Settings ignores, so settings use the ? form. Pane
rows keep the catalogue url exactly as Alfred wrote it, because behaving like
Alfred's own row is the point of them and iCloud needs its :icloud suffix.

Scanning ExtensionKit directly is the fallback for a catalogue that has moved or
cannot be parsed. It costs the curation and the localised names, turning up panes
macOS installs but only ever shows conditionally, under Apple's internal ones.
"""

import hashlib
import json
import os
import plistlib
import sys
import tempfile

EXT_DIR = "/System/Library/ExtensionKit/Extensions"
SETTINGS_APP = "/System/Applications/System Settings.app"
PLUGIN_DIR = os.path.join(SETTINGS_APP, "Contents/PlugIns")
VERSION_PLIST = "/System/Library/CoreServices/SystemVersion.plist"
GLOBAL_PREFS = os.path.expanduser("~/Library/Preferences/.GlobalPreferences.plist")
POINT = "com.apple.Settings.extension.ui"
SETTINGS_NAME = "System Settings"
SCHEME = "x-apple.systempreferences:"

APP_DIRS = ("/Applications", os.path.expanduser("~/Applications"))
# The framework's top-level Resources symlink, not Versions/A, so a version
# bump inside the bundle does not strand this.
FRAMEWORK = "Contents/Frameworks/Alfred Framework.framework/Resources"
CATALOG_PREFIX = "systemsettings"
CATALOG_SUFFIX = ".json"
CACHE_NAME = "settings.json"


def load_plist(path):
    # Broad, unlike every other handler here, because these are arbitrary files
    # macOS ships: a malformed one raises out of expat, not OSError, and any
    # unreadable plist should cost its own entry rather than the whole run.
    try:
        with open(path, "rb") as fh:
            return plistlib.load(fh)
    except Exception:
        return {}


def macos_major():
    version = load_plist(VERSION_PLIST).get("ProductVersion", "")
    head = version.split(".")[0]
    return int(head) if head.isdigit() else 0


def locale_keys():
    """Catalogue name keys and .lproj directory names, most specific first.

    Read from the preferences plist rather than `defaults read`, which costs
    more than everything else this script does to parse the panes.
    """
    prefs = load_plist(GLOBAL_PREFS)
    keys = []

    value = prefs.get("AppleLocale") or ""
    languages = prefs.get("AppleLanguages") or []
    if not value and languages:
        value = str(languages[0]).replace("-", "_")
    # macOS writes en_US@rg=gbzzzz whenever Region differs from the language
    # default, and it is the part before the @ that names a .lproj.
    value = value.split("@")[0]

    if value:
        keys.append(value)
        if "_" in value:
            keys.append(value.split("_")[0])
    keys.extend(["en", "Base"])
    return list(dict.fromkeys(keys))


def catalog_path():
    override = os.environ.get("ALFRED_SETTINGS_CATALOG")
    if override:
        return override if os.path.isfile(override) else None

    major = macos_major()
    for app_dir in APP_DIRS:
        try:
            apps = sorted(a for a in os.listdir(app_dir) if a.startswith("Alfred"))
        except OSError:
            continue
        for app in apps:
            resources = os.path.join(app_dir, app, FRAMEWORK)
            try:
                names = os.listdir(resources)
            except OSError:
                continue

            found = {}
            for name in names:
                if not (
                    name.startswith(CATALOG_PREFIX) and name.endswith(CATALOG_SUFFIX)
                ):
                    continue
                release = name[len(CATALOG_PREFIX) : -len(CATALOG_SUFFIX)]
                if release.isdigit():
                    found[int(release)] = os.path.join(resources, name)
            if found:
                # Alfred adds a catalogue per macOS release, so an OS newer than
                # this Alfred knows falls back to the most recent one it has.
                usable = [v for v in found if v <= major] or list(found)
                return found[max(usable)]
    return None


def resolve_bundles(wanted):
    """Every bundle path declaring each wanted identifier.

    The catalogue names a bundle for display only. Apple Intelligence & Siri
    points at Siri.app, while its searchable settings live in
    SiriPreferenceExtension.appex, so settings are located by identifier rather
    than by the icon path.

    Identifiers are matched against raw Info.plist bytes and only a hit is
    parsed, because parsing all 240-odd of them costs more than the rest of this
    script put together.
    """
    found = {bundle_id: [] for bundle_id in wanted}
    if not wanted:
        return found

    needles = [(bundle_id, bundle_id.encode()) for bundle_id in wanted]
    for directory in (EXT_DIR, PLUGIN_DIR):
        try:
            entries = sorted(os.listdir(directory))
        except OSError:
            continue
        for entry in entries:
            info_path = os.path.join(directory, entry, "Contents/Info.plist")
            try:
                with open(info_path, "rb") as fh:
                    blob = fh.read()
            except OSError:
                continue
            if not any(needle in blob for _, needle in needles):
                continue
            # An identifier can appear in a plist that does not declare it,
            # so confirm before accepting.
            declared = load_plist(info_path).get("CFBundleIdentifier")
            if declared in found:
                found[declared].append(os.path.join(directory, entry))
    return found


_GROUPS = {}


def search_groups(path, keys):
    """Apple's searchable settings for a bundle, grouped by deep-link anchor.

    Returns {anchor: {title: alternate terms}} in the first locale that has any.
    """
    if not path:
        return {}

    memo = (path, tuple(keys))
    if memo in _GROUPS:
        return _GROUPS[memo]
    _GROUPS[memo] = {}

    resources = os.path.join(path, "Contents/Resources")
    for key in keys:
        lproj = os.path.join(resources, key + ".lproj")
        try:
            names = sorted(n for n in os.listdir(lproj) if n.endswith(".searchTerms"))
        except OSError:
            continue

        found = {}
        for name in names:
            groups = load_plist(os.path.join(lproj, name))
            for anchor, group in groups.items():
                for item in group.get("localizableStrings", []):
                    title = (item.get("title") or "").strip()
                    if not title:
                        continue
                    # An index is a comma-separated list of alternate spellings.
                    extra = [
                        t.strip()
                        for t in (item.get("index") or "").split(",")
                        if t.strip()
                    ]
                    bucket = found.setdefault(anchor, {})
                    bucket.setdefault(title, set()).update(extra)
        if found:
            _GROUPS[memo] = found
            return found
    return {}


def match_terms(title, terms):
    # Apple writes Wi‑Fi with a non-breaking hyphen, which nobody types.
    plain = title.replace("‑", "-").replace("‐", "-")
    parts = [title, plain, plain.replace("-", ""), plain.replace("-", " ")]
    parts.extend(sorted(terms))
    return " ".join(dict.fromkeys(p for p in parts if p))


def named(entry, keys):
    names = entry.get("names") or {}
    for key in keys:
        if names.get(key):
            return names[key]
    return next(iter(names.values()), "")


def emit(pane, bundle_id, bundle, url, groups):
    """One row for the pane, then one per individual setting Apple indexes."""
    icon = {"type": "fileicon", "path": bundle or SETTINGS_APP}

    yield (
        True,
        {
            "uid": url,
            "title": pane,
            "subtitle": SETTINGS_NAME,
            "arg": url,
            "match": match_terms(pane, ()),
            "icon": icon,
            "valid": True,
        },
    )

    # Deliberately keyed on the title alone rather than on (anchor, title). A
    # few settings are indexed under two anchors, and two rows reading exactly
    # the same is worse than one that lands a section away. sorted() in
    # search_groups is what makes the surviving anchor deterministic.
    seen = set()
    for anchor, bucket in groups.items():
        for title, extra in bucket.items():
            if title == pane or title in seen:
                continue
            seen.add(title)
            yield (
                False,
                {
                    "uid": bundle_id + "?" + anchor + "#" + title,
                    "title": title,
                    "subtitle": SETTINGS_NAME + " › " + pane,
                    "arg": SCHEME + bundle_id + "?" + anchor,
                    "match": match_terms(title, extra),
                    "icon": icon,
                    "valid": True,
                },
            )


def from_catalog(path, keys):
    with open(path, encoding="utf-8") as fh:
        data = json.load(fh)

    panes = []
    for entry in data.get("panes", []):
        url = entry.get("url")
        pane = named(entry, keys)
        if not url or not pane or not url.startswith(SCHEME):
            continue
        # Alfred appends its own *anchor, and writes iCloud as a :suffix on the
        # Apple Account identifier. Neither belongs in a bundle identifier.
        bundle_id = url[len(SCHEME) :].split("*")[0].split(":")[0]
        icon = entry.get("icon") or ""
        panes.append((pane, bundle_id, icon if os.path.isdir(icon) else "", url))

    located = resolve_bundles({bundle_id for _, bundle_id, _, _ in panes})
    for pane, bundle_id, icon, url in panes:
        candidates = located.get(bundle_id) or []

        groups = {}
        for candidate in candidates:
            groups = search_groups(candidate, keys)
            if groups:
                break

        icon = icon or (candidates[0] if candidates else "")
        yield from emit(pane, bundle_id, icon, url, groups)


def from_extensionkit(keys):
    try:
        entries = sorted(os.listdir(EXT_DIR))
    except OSError:
        entries = []

    for entry in entries:
        if not entry.endswith(".appex"):
            continue
        path = os.path.join(EXT_DIR, entry)
        info = load_plist(os.path.join(path, "Contents/Info.plist"))

        attrs = info.get("EXAppExtensionAttributes") or {}
        extension = info.get("NSExtension") or {}
        if (
            attrs.get("EXExtensionPointIdentifier")
            or extension.get("NSExtensionPointIdentifier")
        ) != POINT:
            continue

        bundle_id = info.get("CFBundleIdentifier")
        if not bundle_id:
            continue

        pane = info.get("CFBundleDisplayName") or info.get("CFBundleName") or entry[:-6]
        yield from emit(
            pane, bundle_id, path, SCHEME + bundle_id, search_groups(path, keys)
        )


def cache_file():
    directory = os.environ.get("alfred_workflow_cache") or tempfile.gettempdir()
    try:
        os.makedirs(directory, exist_ok=True)
    except OSError:
        return ""
    return os.path.join(directory, CACHE_NAME)


def cache_key(catalog, keys):
    """Everything that can change the output, and nothing that cannot.

    Keyed on inputs rather than on elapsed time. Alfred's own cache directive
    expires on a timer, so it cannot tell that the script producing its contents
    has been rewritten, and happily serves results from a version that no longer
    exists. The script's own mtime is in here for exactly that reason. The
    .searchTerms files ship inside the OS, so the build version covers them.
    """
    parts = [
        str(os.path.getmtime(os.path.abspath(__file__))),
        catalog or "",
        str(os.path.getmtime(catalog)) if catalog else "",
        load_plist(VERSION_PLIST).get("ProductBuildVersion", ""),
        "|".join(keys),
    ]
    return hashlib.sha256("\0".join(parts).encode()).hexdigest()


def cached(path, key):
    """The stored payload as raw bytes, never parsed only to be re-serialised."""
    try:
        with open(path, "rb") as fh:
            if fh.readline().strip() == key.encode():
                return fh.read()
    except OSError:
        pass
    return b""


def store(path, key, payload):
    # Written to a unique file beside the target and renamed, so neither a
    # killed run nor two runs overlapping can leave a half-written cache whose
    # first line still reads as a valid key.
    try:
        handle, tmp = tempfile.mkstemp(
            dir=os.path.dirname(path) or ".", prefix=".settings-", suffix=".tmp"
        )
    except OSError:
        return
    try:
        with os.fdopen(handle, "wb") as fh:
            fh.write(key.encode() + b"\n" + payload)
        os.replace(tmp, path)
    except OSError:
        try:
            os.unlink(tmp)
        except OSError:
            pass


def main():
    keys = locale_keys()
    catalog = catalog_path()

    path = cache_file()
    key = cache_key(catalog, keys) if path else ""
    if path:
        payload = cached(path, key)
        if payload:
            sys.stdout.buffer.write(payload)
            return

    rows = []
    if catalog:
        try:
            rows = list(from_catalog(catalog, keys))
        except (OSError, ValueError):
            # A catalogue that is unreadable or not the JSON this expects is
            # exactly what the ExtensionKit scan is for. Branching only on
            # whether the file exists would instead hand Alfred a traceback.
            rows = []
    if not rows:
        rows = list(from_extensionkit(keys))

    # Two catalogue panes can share a bundle, iCloud being an alias for part of
    # Apple Account, so the same setting is emitted under both. The panes
    # themselves keep their own catalogue urls and never collide; it is their
    # settings that do. First one listed wins.
    seen = set()
    unique = []
    for is_pane, item in rows:
        identity = (item["title"], item["arg"])
        if identity in seen:
            continue
        seen.add(identity)
        unique.append((is_pane, item))
    rows = unique

    # Panes first, then settings, each alphabetical: searching for a pane should
    # not have to scroll past its own settings. Alfred reorders by match quality
    # on top of this, so it decides ties rather than the final order.
    rows.sort(key=lambda row: (not row[0], row[1]["title"].lower()))
    items = [item for _, item in rows]

    if not items:
        items = [
            {
                "title": "No settings found",
                "subtitle": "Neither Alfred's catalogue nor "
                + EXT_DIR
                + " could be read",
                "valid": False,
            }
        ]
        # Never cache a failure. Nothing in the key describes why this run found
        # nothing, so a stored failure would outlive whatever caused it and the
        # only way out would be editing this file.
        path = ""

    payload = json.dumps({"items": items}).encode()
    if path:
        store(path, key, payload)
    sys.stdout.buffer.write(payload)


main()
