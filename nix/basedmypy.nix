{
  self,
  lib,
  ...
}: {
  perSystem = {
    config,
    self',
    inputs',
    pkgs,
    ...
  }: {
    packages.basedmypy = pkgs.python3.pkgs.buildPythonPackage rec {
      pname = "mypy";
      version = "2.5.0";
      pyproject = true;

      disabled = pkgs.python3.pythonOlder "3.8";

      src = pkgs.fetchFromGitHub {
        owner = "KotlinIsland";
        repo = "basedmypy";
        rev = "v${version}";
        hash = "sha256-1OCnICKFymO96mPoPs72748Eh4SbQURTSAu9UiPF75I=";
      };
      passthru.updateScript = pkgs.gitUpdater {
        rev-prefix = "v";
      };

      build-system = with pkgs.python3Packages;
        [
          mypy-extensions
          setuptools
          types-psutil
          types-setuptools
          typing-extensions
          wheel
        ]
        ++ lib.optionals (pkgs.python3.pythonOlder "3.11") [tomli];

      dependencies = with pkgs.python3Packages;
        [
          mypy-extensions
          typing-extensions
          self'.packages.basedtyping
        ]
        ++ lib.optionals (pkgs.python3.pythonOlder "3.11") [tomli];

      optional-dependencies = with pkgs.python3Packages; {
        dmypy = [psutil];
        reports = [lxml];
      };

      # Compile mypy with mypyc, which makes mypy about 4 times faster. The compiled
      # version is also the default in the wheels on Pypi that include binaries.
      # is64bit: unfortunately the build would exhaust all possible memory on i686-linux.
      env.MYPY_USE_MYPYC = pkgs.stdenv.buildPlatform.is64bit;

      # when testing reduce optimisation level to reduce build time by 20%
      env.MYPYC_OPT_LEVEL = 1;

      pythonImportsCheck =
        [
          "mypy"
          "mypy.api"
          "mypy.fastparse"
          "mypy.types"
          "mypyc"
          "mypyc.analysis"
        ]
        ++ lib.optionals (!pkgs.stdenv.hostPlatform.isi686) [
          # ImportError: cannot import name 'map_instance_to_supertype' from partially initialized module 'mypy.maptype' (most likely due to a circular import)
          "mypy.report"
        ];

      nativeCheckInputs = with pkgs.python3Packages;
        [
          attrs
          filelock
          pytest-xdist
          pytestCheckHook
          setuptools
          tomli
        ]
        ++ lib.flatten (lib.attrValues optional-dependencies);

      disabledTests =
        [
          # fails with typing-extensions>=4.10
          # https://github.com/python/mypy/issues/17005
          "test_runtime_typing_objects"
        ]
        ++ lib.optionals (pkgs.python3.pythonAtLeast "3.12") [
          # requires distutils
          "test_c_unit_test"
        ];

      disabledTestPaths =
        [
          # fails to find tyoing_extensions
          "mypy/test/testcmdline.py"
          "mypy/test/testdaemon.py"
          # fails to find setuptools
          "mypyc/test/test_commandline.py"
          # fails to find hatchling
          "mypy/test/testpep561.py"
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isi686 [
          # https://github.com/python/mypy/issues/15221
          "mypyc/test/test_run.py"
        ];
    };
    packages.basedtyping = pkgs.python3.pkgs.buildPythonPackage rec {
      pname = "mypy";
      version = "0.1.4";
      pyproject = true;

      disabled = pkgs.python3.pythonOlder "3.8";

      src = pkgs.fetchFromGitHub {
        owner = "KotlinIsland";
        repo = "basedtyping";
        rev = "v${version}";
        hash = "sha256-Buklewf3Hm6Oqsg8+yUBXYfxtPt/ER6RRZHD5LemUso=";
      };

      build-system = with pkgs.python3Packages; [
        poetry-core
        typing-extensions
      ];
    };
  };
}
