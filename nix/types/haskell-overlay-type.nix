{ lib, ... }:

# Use this instead of types.functionTo, because Haskell overlay functions cannot
# be merged (whereas functionTo's can).
lib.mkOptionType {
  name = "haskell-overlay";
  description = ''
    A Haskell overlay function taking 'self' and 'super' args.
  '';
  descriptionClass = "noun";
  check = lib.isFunction;
  merge = lib.mergeOneOption;
}
