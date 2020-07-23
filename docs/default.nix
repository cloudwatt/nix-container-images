{ pkgs, lib }:

let
  options = (pkgs.lib.makeImage{}).options;

  wellSupported = lib.filterOptions
    options
    [ "s6" "image" "users" "environment.systemPackages" "environment.etc" ]
    [ "users.motd" "users.users.<name?>.cryptHomeLuks" ];

in
{
  optionsJsonWellSupported = lib.optionsToJson "options-well-supported" wellSupported;
  optionsMarkdownWellSuppored = lib.optionsToMarkdown "options-well-supported" wellSupported;
}
