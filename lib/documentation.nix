{ pkgs }:

let
  # Remove invisible and internal options.
  optionsListVisible = options: pkgs.lib.filter (opt: opt.visible && !opt.internal) (pkgs.lib.optionAttrSetToDocList options);
in

rec {
  filterOptions = options: supportedPrefixes: unsupportedPrefixes: let
    supported = opt: pkgs.lib.any (p: pkgs.lib.hasPrefix p opt.name) supportedPrefixes;
    unsupported = opt: ! (pkgs.lib.any (p: pkgs.lib.hasPrefix p opt.name) unsupportedPrefixes);
  in
    pkgs.lib.filter unsupported (pkgs.lib.filter supported (optionsListVisible options));
  
  optionsToJson = name: options: pkgs.writeTextFile {
    name = "${name}.json";
    text = (builtins.toJSON options);
  };
  
  optionsToMarkdown = name: options:
    pkgs.runCommand "${name}.md" { buildInputs = [ pkgs.jq ]; } ''
      cat ${optionsToJson "${name}.json" options} | jq '.[] | "#### \(.name)\n\n\(.description)\n\n- type: `\(.type)`\n- default: `\(.default)`\n\n"' -r > $out
    '';
}
