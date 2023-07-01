import base64
import json
import re
from typing import NamedTuple
from urllib import request


def main() -> None:
    version = get_latest_version()
    hash = get_hash(version)
    generate_flake(version, hash)


class Version(NamedTuple):
    identifier: str
    timestamp: str
    file_name: str


def get_latest_version() -> Version:
    with request.urlopen(
        "https://api.github.com/repos/eclipse/eclipse.jdt.ls/tags"
    ) as resp:
        data = resp.read().decode("utf-8")
    latest_version = json.loads(data)[0]["name"][1:]

    with request.urlopen(
        f"https://download.eclipse.org/jdtls/milestones/{latest_version}/latest.txt"
    ) as resp:
        file_name = resp.read().decode("utf-8").strip()

    matches = re.search(r"server-(.+)-(\d+).tar.gz", file_name)
    if not matches:
        raise Exception("hash not found")

    ident, timestamp = matches.groups()
    return Version(ident, timestamp, file_name)


def get_hash(version: Version) -> bytes:
    with request.urlopen(
        f"https://www.eclipse.org/downloads/download.php?file=/jdtls/milestones/{version.identifier}/{version.file_name}.sha256"
    ) as resp:
        hash = resp.read().decode("utf-8")
    encoded_hash = base64.b64encode(bytes.fromhex(hash))
    return encoded_hash


def generate_flake(version: Version, hash: bytes) -> None:
    with open("flake.nix", "r") as template:
        flake = (
            template.read()
            .replace("{{jdtls-version}}", version.identifier)
            .replace("{{jdtls-timestamp}}", version.timestamp)
            .replace("{{jdtls-hash}}", hash.decode("utf-8"))
        )

    with open("flake.nix", "w") as f:
        f.write(flake)


if __name__ == "__main__":
    main()
