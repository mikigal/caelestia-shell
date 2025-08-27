{
  rev,
  lib,
  stdenv,
  makeWrapper,
  makeFontsConf,
  fish,
  ddcutil,
  brightnessctl,
  app2unit,
  cava,
  networkmanager,
  lm_sensors,
  swappy,
  wl-clipboard,
  libqalculate,
  inotify-tools,
  bluez,
  bash,
  hyprland,
  coreutils,
  findutils,
  file,
  material-symbols,
  rubik,
  nerd-fonts,
  qt6,
  quickshell,
  aubio,
  pipewire,
  xkeyboard-config,
  cmake,
  ninja,
  pkg-config,
  caelestia-cli,
  withCli ? false,
  extraRuntimeDeps ? [],
}: let
  runtimeDeps =
    [
      fish
      ddcutil
      brightnessctl
      app2unit
      cava
      networkmanager
      lm_sensors
      swappy
      wl-clipboard
      libqalculate
      inotify-tools
      bluez
      bash
      hyprland
      coreutils
      findutils
      file
    ]
    ++ extraRuntimeDeps
    ++ lib.optional withCli caelestia-cli;

  fontconfig = makeFontsConf {
    fontDirectories = [material-symbols rubik nerd-fonts.caskaydia-cove];
  };
in
  stdenv.mkDerivation {
    pname = "caelestia-shell";
    version = "${rev}";
    src = ./..;

    nativeBuildInputs = [cmake ninja pkg-config makeWrapper qt6.wrapQtAppsHook];
    buildInputs = [quickshell aubio pipewire xkeyboard-config qt6.qtbase qt6.qtdeclarative];
    propagatedBuildInputs = runtimeDeps;

    cmakeBuildType = "Release";
    cmakeFlags = [
      (lib.cmakeFeature "INSTALL_LIBDIR" "${placeholder "out"}/lib")
      (lib.cmakeFeature "INSTALL_QMLDIR" qt6.qtbase.qtQmlPrefix)
      (lib.cmakeFeature "INSTALL_QSCONFDIR" "${placeholder "out"}/share/caelestia-shell")
      (lib.cmakeFeature "GIT_REVISION" rev)
    ];

    patchPhase = ''
      substituteInPlace assets/pam.d/fprint \
        --replace-fail pam_fprintd.so /run/current-system/sw/lib/security/pam_fprintd.so
    '';

    postInstall = ''
      makeWrapper ${quickshell}/bin/qs $out/bin/caelestia-shell \
      	--prefix PATH : "${lib.makeBinPath runtimeDeps}" \
      	--set FONTCONFIG_FILE "${fontconfig}" \
      	--set CAELESTIA_LIB_DIR $out/lib \
        --set CAELESTIA_XKB_RULES_PATH ${xkeyboard-config}/share/xkeyboard-config-2/rules/base.lst \
      	--add-flags "-p $out/share/caelestia-shell"
    '';

    meta = {
      description = "A very segsy desktop shell";
      homepage = "https://github.com/caelestia-dots/shell";
      license = lib.licenses.gpl3Only;
      mainProgram = "caelestia-shell";
    };
  }
