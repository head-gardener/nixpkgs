{ lib
, stdenv
, fetchFromGitHub
, cmake
, pkg-config
, cairo
, hyprlang
, librsvg
, libzip
, nix-update-script
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "hyprcursor";
  version = "0.1.5";

  src = fetchFromGitHub {
    owner = "hyprwm";
    repo = "hyprcursor";
    rev = "refs/tags/v${finalAttrs.version}";
    hash = "sha256-e6+fu30inlTIdflotS6l7qYusslKMNkhZVNLn9ZSogg=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cairo
    hyprlang
    librsvg
    libzip
  ];

  outputs = [
    "out"
    "dev"
    "lib"
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    homepage = "https://github.com/hyprwm/hyprcursor";
    description = "The hyprland cursor format, library and utilities";
    changelog = "https://github.com/hyprwm/hyprcursor/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ iynaix ];
    mainProgram = "hyprcursor-util";
    platforms = lib.platforms.linux;
  };
})
