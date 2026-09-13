# SPDX-FileCopyrightText: 2026 PythonWoods <dev@pythonwoods.dev>
# SPDX-License-Identifier: Apache-2.0
"""Regenerate `assets/sarif-showcase.svg` from the SARIF shape the engine really emits.

The asset is a terminal capture, and it had drifted twice over in ways no text sweep
finds. It named `PythonWoods/zenzic-action`, a retired repository slug; and the SARIF
result it depicted predated this release's contract, missing `partialFingerprints`,
`region.startColumn`, `artifactLocation.uriBaseId` and the `properties` block.

Editing the SVG in place is not an option: the text nodes carry `textLength` and a
`clip-path` computed for the original strings, so a longer string is squeezed into the
old width and renders distorted. It has to be re-rendered, which is why this script
exists rather than a patch.

The payload below is a verbatim single result from a real
`zenzic check all --format sarif` run over a fixture containing one AWS test key, with
only the tool version replaced by `x.y.z` so the asset does not go stale at every
release. Regenerate whenever the SARIF contract changes:

    uv run python scripts/generate_sarif_showcase.py
"""

from __future__ import annotations

import json
from pathlib import Path

from rich.console import Console
from rich.syntax import Syntax
from rich.text import Text

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "sarif-showcase.svg"

#: One real result, as emitted. `partialFingerprints` carries both keys because this
#: finding has a source line; a file-level finding such as Z502 correctly carries only
#: `zenzicFindingV1`.
PAYLOAD = {
    "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
    "version": "2.1.0",
    "runs": [
        {
            "tool": {
                "driver": {
                    "name": "Zenzic",
                    "version": "x.y.z",
                    "informationUri": "https://zenzic.dev",
                }
            },
            "results": [
                {
                    "ruleId": "Z201",
                    "level": "error",
                    "message": {
                        "text": "Secret detected (aws-access-key) — rotate immediately."
                    },
                    "locations": [
                        {
                            "physicalLocation": {
                                "artifactLocation": {
                                    "uri": "docs/setup.md",
                                    "uriBaseId": "%SRCROOT%",
                                },
                                "region": {"startLine": 15, "startColumn": 35},
                            }
                        }
                    ],
                    "partialFingerprints": {
                        "zenzicFindingV1": "4d5b084fada584ffb4c7247821d94aaae9e0075"
                        "90aadfdafa0230ddd438a5f42",
                        "primaryLocationLineHash": "e053f8610abc996735d77e857029d8e094f4"
                        "18cd7965e6547af6e656f6512b40",
                    },
                    "properties": {
                        "security-severity": "9.5",
                        "is_likely_placeholder": True,
                    },
                }
            ],
        }
    ],
}


def main() -> int:
    console = Console(record=True, width=100, force_terminal=True)

    console.print(Text("Run PythonWoods-Dev/zenzic-action@v2", style="bold white"))
    for line in ("  with:", "    version: x.y.z", "    format: sarif", "    upload-sarif: true"):
        console.print(Text(line, style="grey70"))
    console.print()
    console.print(
        Text.assemble(("Executing: ", "bold cyan"), ("uvx zenzic check all --format sarif --ci", "white"))
    )
    console.print(Text.assemble(("Saving to: ", "bold cyan"), ("zenzic-results.sarif", "white")))
    console.print()
    console.print(Syntax(json.dumps(PAYLOAD, indent=2), "json", theme="ansi_dark", word_wrap=False))
    console.print()
    console.print(Text("::group::SARIF Upload", style="grey50"))
    console.print(Text("Uploading results to GitHub Code Scanning...", style="white"))
    console.print(Text("Payload accepted. Findings available in Security tab.", style="bold green"))
    console.print(Text("::endgroup::", style="grey50"))

    console.save_svg(str(OUT), title="Zenzic SARIF Upload")
    print(f"wrote {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
