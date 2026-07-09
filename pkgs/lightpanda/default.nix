{ pkgs, ... }:
let
  version = "0.3.4";
  platform = pkgs.stdenv.hostPlatform.system;
  sources = {
    x86_64-linux = pkgs.fetchurl {
      url = "https://github.com/lightpanda-io/browser/releases/download/${version}/lightpanda-x86_64-linux";
      hash = "sha256-u88VtlHeRseNGz9WSJXnK+uNnYHFp/mwvQAEnCsxH24=";
    };
    aarch64-linux = pkgs.fetchurl {
      url = "https://github.com/lightpanda-io/browser/releases/download/${version}/lightpanda-aarch64-linux";
      hash = "sha256-A0ng+VuME7mMDtOs4Xa7zsrs7EZ0qaLPrt1TeU9CYJQ=";
    };
    x86_64-darwin = pkgs.fetchurl {
      url = "https://github.com/lightpanda-io/browser/releases/download/${version}/lightpanda-x86_64-macos";
      hash = "sha256-AOoUlaoGMdiPMFVsKXDWI5YeNwTX3Pp2Ihlw4q8EjSA=";
    };
    aarch64-darwin = pkgs.fetchurl {
      url = "https://github.com/lightpanda-io/browser/releases/download/${version}/lightpanda-aarch64-macos";
      hash = "sha256-jydTB9N3yCwUyCeIbsFm+aNAtJxtFzJDnmqfO6q18i0=";
    };
  };
  lightpanda = pkgs.stdenv.mkDerivation {
    pname = "lightpanda";
    inherit version;

    src = sources.${platform};

    dontUnpack = true;

    nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      pkgs.autoPatchelfHook
    ];

    buildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      pkgs.stdenv.cc.cc.lib
    ];

    installPhase = ''
      runHook preInstall

      install -Dm755 $src $out/bin/lightpanda

      runHook postInstall
    '';

    meta = {
      description = "Headless browser designed for AI and automation";
      homepage = "https://lightpanda.io";
      license = pkgs.lib.licenses.agpl3Only;
      mainProgram = "lightpanda";
      platforms = builtins.attrNames sources;
      sourceProvenance = with pkgs.lib.sourceTypes; [ binaryNativeCode ];
    };
  };
in
{
  home.packages = [
    lightpanda
  ];
}
