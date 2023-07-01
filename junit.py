import base64
import json
import re
from urllib import request


def main() -> None:
    platform_version = get_latest_platform_version()
    hash = get_hash(platform_version)
    generate_flake(platform_version, hash)


def get_latest_platform_version() -> str:
    with request.urlopen(
        "https://api.github.com/repos/junit-team/junit5/releases/latest"
    ) as resp:
        data = resp.read().decode("utf-8")

    json_data = json.loads(data)
    name = json_data["name"]
    body = json_data["body"]

    matches = re.search(rf"^{name} = Platform (.+) \+ Jupiter", body)
    if not matches:
        raise Exception("platform version not found")

    platform_version = matches.groups()[0]
    return platform_version


def get_hash(platform_version: str) -> bytes:
    with request.urlopen(
        f"https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/{platform_version}/junit-platform-console-standalone-{platform_version}.jar.sha512"
    ) as resp:
        hash = resp.read().decode("utf-8")
    encoded_hash = base64.b64encode(bytes.fromhex(hash))
    return encoded_hash


def generate_flake(version: str, hash: bytes) -> None:
    with open("flake.nix", "r") as template:
        flake = (
            template.read()
            .replace("{{junit-version}}", version)
            .replace("{{junit-hash}}", hash.decode("utf-8"))
        )

    with open("flake.nix", "w") as f:
        f.write(flake)


if __name__ == "__main__":
    main()
