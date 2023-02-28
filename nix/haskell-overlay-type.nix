{ lib, ... }:

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
  merge = _loc: defs:
    let
      logWarning =
        if builtins.length defs > 1
        then builtins.trace "WARNING[haskell-flake]: Multiple haskell overlays are applied in arbitrary order." null
        else null;
      overlays =
        map (x: x.value)
          (builtins.seq
            logWarning
            defs);
    in
    lib.composeManyExtensions overlays;
}
