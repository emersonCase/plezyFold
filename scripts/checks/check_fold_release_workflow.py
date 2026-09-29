#!/usr/bin/env python3
"""Guard plezyFold's tag-to-APK release contract."""

from pathlib import Path
import re
import sys

from workflow_yaml import job_block


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_WORKFLOW = ROOT / ".github/workflows/fold-release.yml"
if len(sys.argv) > 2:
    raise SystemExit(f"Usage: {Path(sys.argv[0]).name} [workflow-path]")
WORKFLOW = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else DEFAULT_WORKFLOW
text = WORKFLOW.read_text(encoding="utf-8")
errors: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


build = job_block(text, "build-and-test")
publish = job_block(text, "publish-release")

require(
    re.search(r'(?ms)^on:\n  push:\n    tags:\n      - ["\']v\*\.\*\.\*["\']\n', text)
    is not None,
    "release workflow must trigger only from v-prefixed version tags",
)
for forbidden_trigger in ("pull_request", "workflow_dispatch", "schedule"):
    require(
        re.search(rf"(?m)^  {forbidden_trigger}:", text) is None,
        f"release workflow must not use the {forbidden_trigger} trigger",
    )

require(bool(build), "missing build-and-test job")
require(bool(publish), "missing publish-release job")
require("permissions:\n      contents: read" in build, "build job must remain read-only")
require(
    '[[ ! "$RELEASE_TAG" =~ ^v[0-9]+\\.[0-9]+\\.[0-9]+$ ]]' in build,
    "build job must strictly validate vX.Y.Z tags",
)

ordered_build_steps = (
    "Install wakelock_plus development dependencies",
    "Run repository guards",
    "Analyze code",
    "Run unit and widget tests",
    "Build signed release APK",
    "Upload tested APK",
)
positions = [build.find(f"      - name: {name}\n") for name in ordered_build_steps]
require(all(position >= 0 for position in positions), "build job is missing a required validation or build step")
require(positions == sorted(positions), "tests and analysis must complete before the APK is built and uploaded")
require(
    "working-directory: packages/wakelock_plus" in build,
    "analysis requires the vendored wakelock_plus development dependencies",
)
require(
    "Required Android signing secret is not configured" in build
    and "ANDROID_KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}" in build,
    "release APK must require configured persistent signing material",
)
require(
    "build/app/outputs/flutter-apk/app-release.apk" in build,
    "release workflow must publish the signed release APK",
)
require("sha256sum" in build, "build job must checksum the release APK")

require("needs: build-and-test" in publish, "publication must require the tested build job")
require("permissions:\n      contents: write" in publish, "only the publication job may write contents")
require(
    "sha256sum --check SHA256SUMS" in publish,
    "publication must verify the downloaded APK checksum",
)
require("draft: false" in publish, "tag checkpoints must publish a non-draft release")
require(
    "tag_name: ${{ github.ref_name }}" in publish,
    "release must remain bound to the pushed tag",
)

if errors:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    raise SystemExit(1)

print("fold release workflow checks passed")
