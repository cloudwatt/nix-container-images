{ pkgs, lib }:

with pkgs.lib;

let
  options = (makeImage{}).options;

  # Remove invisible and internal options.
  optionsListVisible = pkgs.lib.filter (opt: opt.visible && !opt.internal) (pkgs.lib.optionAttrSetToDocList options);

  optionsFiltering = supportedPrefixes: unsupportedPrefixes: let
    supported = opt: any (p: pkgs.lib.hasPrefix p opt.name) supportedPrefixes;
    unsupported = opt: ! (any (p: pkgs.lib.hasPrefix p opt.name) unsupportedPrefixes);
  in
    pkgs.lib.filter unsupported (pkgs.lib.filter supported optionsListVisible);

  optionsWellSupported = optionsFiltering
    [ "s6" "image" "users" "environment.systemPackages" "environment.etc" ]
    [ "users.motd" "users.users.<name?>.cryptHomeLuks" ];

in
rec {
  optionsJson = pkgs.writeTextFile {
    name = "options-well-supported.json";
    text = (builtins.toJSON optionsWellSupported);
  };

  optionsMarkdown = pkgs.runCommand "options-well-supported-generated.md" { buildInputs = [ pkgs.jq]; } ''
    cat ${optionsJson} | jq '.[] | "#### \(.name)\n\n\(.description)\n\n- type: `\(.type)`\n- default: `\(.default)`\n\n"' -r > $out
  '';
}
