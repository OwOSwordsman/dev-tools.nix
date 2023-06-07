import re
import subprocess


def main() -> None:
    with open("template.nix", "r") as template:
        updatedTemplate = template.read().replace("{{version}}", "1.21.0").replace("{{timestamp}}", "202303161431")
    with open("flake.nix", "w") as flake:
        flake.write(updatedTemplate)
    
    process = subprocess.run(["nix", "build"], capture_output=True)
    matches = re.search(r"\s+got:\s+(sha256-.+=)", process.stderr.decode())
    if not matches:
        raise Exception("hash not found")
    hash = matches.group(1)

    with open("flake.nix", "w") as flake:
        flake.write(updatedTemplate.replace("pkgs.lib.fakeHash", f'"{hash}"'))


if __name__ == "__main__":
    main()
