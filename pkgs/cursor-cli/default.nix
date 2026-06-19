{ pkgs, ... }:
let
  version = "2026.06.04-5fd875e";
  platform = pkgs.stdenv.hostPlatform.system;
  sources = {
    x86_64-linux = pkgs.fetchurl {
      url = "https://downloads.cursor.com/lab/${version}/linux/x64/agent-cli-package.tar.gz";
      hash = "sha256-VCWqsp+KAdN33j3H90VXOa1Zgp4IeeoMQpa9nuxSAwA=";
    };
    aarch64-linux = pkgs.fetchurl {
      url = "https://downloads.cursor.com/lab/${version}/linux/arm64/agent-cli-package.tar.gz";
      hash = "sha256-840iUUKLt1duoq1LbxIFgwtRmvTna7A6Ofi4wbkEKkI=";
    };
    x86_64-darwin = pkgs.fetchurl {
      url = "https://downloads.cursor.com/lab/${version}/darwin/x64/agent-cli-package.tar.gz";
      hash = "sha256-v0NSz3PECoPJg0C9UmmgpcuE9QEEJxdr9tZIkerKYiY=";
    };
    aarch64-darwin = pkgs.fetchurl {
      url = "https://downloads.cursor.com/lab/${version}/darwin/arm64/agent-cli-package.tar.gz";
      hash = "sha256-GswPdGwhm/kweOTO66vWTpoptfRKN0bOmjCwFLdG0sc=";
    };
  };
  cursor-cli = pkgs.stdenv.mkDerivation {
    pname = "cursor-cli";
    version = "0-unstable-${version}";

    src = sources.${platform};

    buildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      pkgs.zlib
    ];

    nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      pkgs.autoPatchelfHook
      pkgs.stdenv.cc.cc.lib
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/cursor-agent
      cp -r * $out/share/cursor-agent/
      ln -s $out/share/cursor-agent/cursor-agent $out/bin/agent
      ln -s $out/share/cursor-agent/cursor-agent $out/bin/cursor-agent

      runHook postInstall
    '';

    meta = {
      description = "Cursor CLI";
      homepage = "https://cursor.com/cli";
      license = pkgs.lib.licenses.unfree;
      mainProgram = "agent";
      platforms = builtins.attrNames sources;
      sourceProvenance = with pkgs.lib.sourceTypes; [ binaryNativeCode ];
    };
  };
in
{
  home.packages = [
    cursor-cli
  ];
}
