kos = widen2comm(functional_profiles(kind="ko_names_relab")..., featurecol=:func)
kos = view(kos, species=map(x-> !in(x, ("UNMAPPED", "UNGROUPED")), featurenames(kos)))
pfams = widen2comm(functional_profiles(kind="pfam_names_relab")..., featurecol=:func)
pfams = view(pfams, species=map(x-> !in(x, ("UNMAPPED", "UNGROUPED")), featurenames(pfams)))
ecs = widen2comm(functional_profiles(kind="ec_names_relab")..., featurecol=:func)
ecs = view(ecs, species=map(x-> !in(x, ("UNMAPPED", "UNGROUPED")), featurenames(ecs)))
