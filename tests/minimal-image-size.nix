{ pkgs, lib }:

let
  minimal = lib.makeImage (
    {config, pkgs, ...}: {
      config.image.name = "minimal";
    }
  );

in
pkgs.runCommand "minimal-image-size" {} ''
  set -e
  MINIMAL_SIZE=25000

  SIZE=$(du ${minimal} | cut -f1)
  if [[ $SIZE -ge $MINIMAL_SIZE ]];
  then
    echo "Minimal image size should be less than $MINIMAL_SIZE while it is $SIZE"
    exit 1
  else
    echo "Minimal image size is $SIZE" | tee $out
  fi    
''

