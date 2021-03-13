# # Functional profiles
#
# Functional profiles for metagenomic data
# were generated by HUMAnN version 3.
# 
# They come in several flavors.
# The most expansive characterization is using UniRef90 IDs,
# which are generated for all protein sequences based on
# clustering at 90% identity,
# regardless of whether additional functional information is available.
#
# Other protein identification schemas,
# in rough order of number of granularity
# (and also size):
#
# - Pfam
# - Kegg Orthology (KO)
# - Level 4 Enzyme commision (EC) number
# - Pathways
#
using ResonanceMicrobiome
using Microbiome.MultivariateStats
using CairoMakie
using AbstractPlotting.ColorSchemes


colormap = ColorSchemes.tab20.colors

#-

## note - this can take a long time
all_unirefs = functional_profiles(:unirefs)
all_metadata = resonance_metadata(name.(samples(all_unirefs)))
kids_metadata = filter(row-> !ismissing(row.correctedAgeDays), all_metadata)


all_unirefs_dm = braycurtis(all_unirefs)
all_unirefs_pco = fit(MDS, all_unirefs_dm, distances=true)

kids_unirefs = all_unirefs[:, kids_metadata.sample]
kids_unirefs = kids_unirefs[vec(featuretotals(kids_unirefs) .!= 0), :]
kids_metadata.frac_unirefs_identified = vec(1 .- sum(abundances(kids_unirefs["UNMAPPED", :]), dims=1))

kids_dm = braycurtis(kids_unirefs)
kids_pco = fit(MDS, kids_dm, distances=true)


#- 

figure1 = Figure(resolution=(1200, 800));

fig1a = figure1[1,1] = Axis(figure1, title="All participants", xlabel=mds_format(all_unirefs_pco, 1), ylabel=mds_format(all_unirefs_pco, 2))
scatter!(fig1a, projection(all_unirefs_pco)[:,1], projection(all_unirefs_pco)[:,2], 
    color=categorical_colors(all_metadata.ageLabel, ["Prenatal", "1 and under", "1 to 2", "2 and over", missing], colormap[[9, 2, 3, 5, 15]]))
figure1

#- 

fig1b = figure1[1,2] = Axis(figure1, title="Children", xlabel=mds_format(kids_pco, 1), ylabel=mds_format(kids_pco, 2))
scatter!(fig1b, projection(kids_pco)[:,1] .* -1, projection(kids_pco)[:,2],
        color=categorical_colors(kids_metadata.ageLabel, ["Prenatal", "1 and under", "1 to 2", "2 and over", missing], colormap[[9, 2, 3, 5, 15]]))

fig1ab_legend = figure1[1,3] = Legend(figure1,
    [
        MarkerElement(color = colormap[9], marker = 'o', strokecolor = :black)
        MarkerElement(color = colormap[2], marker = 'o', strokecolor = :black)
        MarkerElement(color = colormap[3], marker = 'o', strokecolor = :black)
        MarkerElement(color = colormap[5], marker = 'o', strokecolor = :black)
    ],
    ["mom", "1 and under", "1 to 2", "over 2"])


fig1c = figure1[2, 1:2] = Axis(figure1, xlabel=mds_format(kids_pco, 1), ylabel="Age (years)")

scatter!(fig1c, projection(kids_pco)[:,1] .* -1, kids_metadata.correctedAgeDays ./ 365, color=kids_metadata.frac_unirefs_identified,
        colormap=:heat)

fig1c_legend = figure1[2,3] = Colorbar(figure1, halign=:left, limits=extrema(kids_metadata.frac_unirefs_identified), width=25, label="fraction idendified",
                                        colormap=:heat)
figure1
CairoMakie.save("figures/04_genefamilies.svg", figure1)

#-

all_ecs = functional_profiles(:ecs)
all_kos = functional_profiles(:kos)
all_pfams = functional_profiles(:pfams)

all_ecs_dm = braycurtis(all_ecs)
all_ecs_pco = fit(MDS, all_ecs_dm, distances=true)
all_kos_dm = braycurtis(all_kos)
all_kos_pco = fit(MDS, all_kos_dm, distances=true)
all_pfams_dm = braycurtis(all_pfams)
all_pfams_pco = fit(MDS, all_pfams_dm, distances=true)


kids_ecs = all_ecs[:, kids_metadata.sample]
kids_ecs = kids_ecs[vec(featuretotals(kids_ecs) .!= 0), :]
kids_metadata.frac_ecs_identified = vec(1 .- sum(abundances(kids_ecs[["UNMAPPED", "UNGROUPED"], :]), dims=1))
kids_kos = all_kos[:, kids_metadata.sample]
kids_kos = kids_kos[vec(featuretotals(kids_kos) .!= 0), :]
kids_metadata.frac_kos_identified = vec(1 .- sum(abundances(kids_kos[["UNMAPPED", "UNGROUPED"], :]), dims=1))
kids_pfams = all_pfams[:, kids_metadata.sample]
kids_pfams = kids_pfams[vec(featuretotals(kids_pfams) .!= 0), :]
kids_metadata.frac_pfams_identified = vec(1 .- sum(abundances(kids_pfams[["UNMAPPED", "UNGROUPED"], :]), dims=1))

kids_ecs_dm = braycurtis(kids_ecs)
kids_ecs_pco = fit(MDS, kids_ecs_dm, distances=true)
kids_kos_dm = braycurtis(kids_kos)
kids_kos_pco = fit(MDS, kids_kos_dm, distances=true)
kids_pfams_dm = braycurtis(kids_pfams)
kids_pfams_pco = fit(MDS, kids_pfams_dm, distances=true)


#-

figure2 = Figure(resolution=(1600, 900));

fig2a = Axis(figure2[1,1], xlabel = mds_format(all_ecs_pco, 1),    ylabel = mds_format(all_ecs_pco, 2))
fig2b = Axis(figure2[1,2], xlabel = mds_format(all_kos_pco, 1),    ylabel = mds_format(all_kos_pco, 2))
fig2c = Axis(figure2[1,3], xlabel = mds_format(all_pfams_pco, 1),  ylabel = mds_format(all_pfams_pco, 2))
fig2d = Axis(figure2[2,1], xlabel = mds_format(kids_ecs_pco, 1),   ylabel = mds_format(kids_ecs_pco, 2))
fig2e = Axis(figure2[2,2], xlabel = mds_format(kids_kos_pco, 1),   ylabel = mds_format(kids_kos_pco, 2))
fig2f = Axis(figure2[2,3], xlabel = mds_format(kids_pfams_pco, 1), ylabel = mds_format(kids_pfams_pco, 2))

Label(figure2[0, 1], "ECs", textsize=30, tellwidth=false)
Label(figure2[1, 2], "KOs", textsize=30, tellwidth=false)
Label(figure2[1, 3], "Pfams", textsize=30, tellwidth=false)
Label(figure2[2, 0], "All", textsize=30, tellheight=false)
Label(figure2[3, 1], "Kids", textsize=30, tellheight=false)

figure2

fig2_legend = Legend(figure2[:, end+1], [
        MarkerElement(color = colormap[9], marker = :circle, strokecolor = :black),
        MarkerElement(color = colormap[2], marker = :circle, strokecolor = :black),
        MarkerElement(color = colormap[3], marker = :circle, strokecolor = :black),
        MarkerElement(color = colormap[5], marker = :circle, strokecolor = :black)
    ],
    ["mom", "1 and under", "1 to 2", "over 2"])

scatter!(fig2a, projection(all_ecs_pco)[:,1], projection(all_ecs_pco)[:,2], 
    color=categorical_colors(all_metadata.ageLabel, ["Prenatal", "1 and under", "1 to 2", "2 and over", missing],
    colormap[[9, 2, 3, 5, 15]]))
scatter!(fig2b, projection(all_kos_pco)[:,1], projection(all_kos_pco)[:,2], 
    color=categorical_colors(all_metadata.ageLabel, ["Prenatal", "1 and under", "1 to 2", "2 and over", missing],
    colormap[[9, 2, 3, 5, 15]]))
scatter!(fig2c, projection(all_pfams_pco)[:,1], projection(all_pfams_pco)[:,2], 
    color=categorical_colors(all_metadata.ageLabel, ["Prenatal", "1 and under", "1 to 2", "2 and over", missing],
    colormap[[9, 2, 3, 5, 15]]))
scatter!(fig2d, projection(kids_ecs_pco)[:,1], projection(kids_ecs_pco)[:,2],
    color=categorical_colors(kids_metadata.ageLabel, ["Prenatal", "1 and under", "1 to 2", "2 and over", missing],
    colormap[[9, 2, 3, 5, 15]]))
scatter!(fig2e, projection(kids_kos_pco)[:,1], projection(kids_kos_pco)[:,2], 
    color=categorical_colors(kids_metadata.ageLabel, ["Prenatal", "1 and under", "1 to 2", "2 and over", missing],
    colormap[[9, 2, 3, 5, 15]]))
scatter!(fig2f, projection(kids_pfams_pco)[:,1], projection(kids_pfams_pco)[:,2], 
    color=categorical_colors(kids_metadata.ageLabel, ["Prenatal", "1 and under", "1 to 2", "2 and over", missing],
    colormap[[9, 2, 3, 5, 15]]))
figure2


CairoMakie.save("figures/04_other_functions.svg", figure2)
