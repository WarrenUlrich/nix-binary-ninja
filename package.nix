{
  lib,
  stdenv,
  callPackage,
  fetchurl,
  auto-patchelf,
  autoPatchelfHook,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  unzip,
  libGL,
  glib,
  fontconfig,
  libxi,
  libxrender,
  libxcb-image,
  libxcb-render-util,
  dbus,
  libxkbcommon,
  wayland,
  python3,
  libxml2,
  xcbutilwm,
  xcbutilkeysyms,
  curl,
  binaryNinjaEdition ? "personal",
  forceWayland ? false,
  overrideSource ? null,
}:
let
  sources = callPackage ./sources.nix { };
  platformSources = sources.editions.${binaryNinjaEdition};
  source =
    if overrideSource != null then
      overrideSource
    else if builtins.hasAttr stdenv.hostPlatform.system platformSources then
      platformSources.${stdenv.hostPlatform.system}
    else
      throw "No source for system ${stdenv.hostPlatform.system}";
  desktopIcon = fetchurl {
    url = "https://docs.binary.ninja/img/logo.png";
    hash = "sha256-waXgwz9lSJ2zPahtqCP+ZdL5Ac6RZ4/pnz7iB4bTs4c=";
  };
in
stdenv.mkDerivation {
  pname = "binary-ninja";
  inherit (sources) version;
  src = source;
  nativeBuildInputs = [
    makeWrapper
    auto-patchelf
    autoPatchelfHook
    python3.pkgs.wrapPython
    copyDesktopItems
  ];
  buildInputs = [
    unzip
    libGL
    glib
    fontconfig
    libxi
    libxrender
    libxcb-image
    libxcb-render-util
    libxkbcommon
    dbus
    wayland
    libxml2.out
    xcbutilwm
    xcbutilkeysyms
    curl
  ];
  autoPatchelfIgnoreMissingDeps = [
    "libQt6ShaderTools.so.6"
    "libQt6QuickVectorImageGenerator.so.6"
    "libQt6Quick.so.6"
    "libQt6Qml.so.6"
    "libQt6PrintSupport.so.6"
  ];
  pythonDeps = [ python3.pkgs.pip ];
  appendRunpaths = [ "${lib.getLib python3}/lib" ];
  buildPhase = ":";
  desktopItems = [
    (makeDesktopItem {
      name = "Binary Ninja";
      exec = "binaryninja";
      icon = "binaryninja";
      desktopName = "Binary Ninja";
      comment = "Binary Ninja is an interactive decompiler, disassembler, debugger, and binary analysis platform built by reverse engineers, for reverse engineers";
      categories = [ "Development" ];
    })
  ];
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    mkdir -p $out/opt/binaryninja
    mkdir -p $out/share/pixmaps
    cp -r * $out/opt/binaryninja

    addAutoPatchelfSearchPath "$out/opt/binaryninja"
    addAutoPatchelfSearchPath "$out/opt/binaryninja/plugins"
    addAutoPatchelfSearchPath "$out/opt/binaryninja/plugins/lldb/lib"
    addAutoPatchelfSearchPath "$out/opt/binaryninja/qt/platforms"
    addAutoPatchelfSearchPath "$out/opt/binaryninja/qt/xcbglintegrations"
    addAutoPatchelfSearchPath "$out/opt/binaryninja/qt/imageformats"
    addAutoPatchelfSearchPath "$out/opt/binaryninja/qt/wayland-decoration-client"
    addAutoPatchelfSearchPath "$out/opt/binaryninja/qt/wayland-graphics-integration-client"
    addAutoPatchelfSearchPath "$out/opt/binaryninja/qt/wayland-shell-integration"
    addAutoPatchelfSearchPath "$out/opt/binaryninja/python3/PySide6"
    addAutoPatchelfSearchPath "$out/opt/binaryninja/python3/shiboken6"

    cp ${desktopIcon} $out/share/pixmaps/binaryninja.png
    chmod +x $out/opt/binaryninja/binaryninja
    buildPythonPath "$pythonDeps"
    makeWrapper $out/opt/binaryninja/binaryninja $out/bin/binaryninja \
      --prefix PYTHONPATH : "$program_PYTHONPATH" \
      ${lib.optionalString forceWayland "--set QT_QPA_PLATFORM wayland"}
    runHook postInstall
  '';
  preFixup = ''
    patchelf $out/opt/binaryninja/plugins/lldb/lib/liblldb.so.* \
      --replace-needed libxml2.so.2 libxml2.so
  '';
  meta = {
    mainProgram = "binaryninja";
  };
}
