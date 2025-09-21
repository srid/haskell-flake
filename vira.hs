-- Pipeline configuration for Vira
\ctx pipeline ->
  let isMaster = ctx.branch == "master"
  in pipeline
    & #signoff % #enable .~ True
    & #cachix % #enable .~ False
    & #attic % #enable .~ isMain
