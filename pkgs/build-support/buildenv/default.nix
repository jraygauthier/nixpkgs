# buildEnv creates a tree of symlinks to the specified paths.  This is
# a fork of the buildEnv in the Nix distribution.  Most changes should
# eventually be merged back into the Nix distribution.

{ lib, perl, runCommand }:

args@ { 
  name

, # The manifest file (if any).  A symlink $out/manifest will be
  # created to it.
  manifest ? ""
  
, # The paths to symlink.
  paths
  
, # Whether to ignore collisions or abort.
  ignoreCollisions ? false

, # The paths (relative to each element of `paths') that we want to
  # symlink (e.g., ["/bin"]).  Any file not inside any of the
  # directories in the list is not symlinked.
  pathsToLink ? ["/"]

, # Shell command to run after building the symlink tree.
  postBuild ? ""

, # Additional inputs. Handy e.g. if using makeWrapper in `postBuild`.
  buildInputs ? []

, passthru ? {}

, ...
}:

with lib;

let
  fixedAttrs = [ "preferLocalBuild" "buildCommand" ];
  handledAttrs = 
    [ "manifest" "paths" "ignoreCollisions" "passthru"
      "pathsToLink" "postBuild" "buildInputs" ];

  additionalAttrsSet = removeAttrs args handledAttrs;
  erroneousAttrs = filter (x: hasAttr x additionalAttrsSet) fixedAttrs;
in

if (0 != length erroneousAttrs) then
  throw "Attributes: \{ ${concatStrings (intersperse "," erroneousAttrs)} \} should not be used as input."
else 
  runCommand name
    (
      { inherit manifest paths ignoreCollisions passthru pathsToLink postBuild buildInputs;
        preferLocalBuild = true;
      } // additionalAttrsSet
    )
    ''
      ${perl}/bin/perl -w ${./builder.pl}
      eval "$postBuild"
    ''