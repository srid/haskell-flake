{ lib, ... }:

let
  log = import ../logging.nix { };
in
# WARNING: While the order is deterministic, it is not
  # determined by the user. Thus overlays may be applied in
  # an unexpected order.
  # We need: https://github.com/NixOS/nixpkgs/issues/215486
lib.types.mkOptionType {
  name = "haskellOverlay";
  description = "An Haskell overlay function";
  descriptionClass = "noun";
  # NOTE: This check is not exhaustive, as there is no way
  # to check that the function takes two arguments, and
  # returns an attrset.
  check = lib.isFunction;
  merge = _loc: defs':
    let
      defs =
        if builtins.length defs' > 1
        then log.traceWarning "Multiple haskell overlays are applied in arbitrary order" defs'
        else defs';
      overlays =
        map (x: x.value) defs;
    in
    lib.composeManyExtensions overlays;
}
