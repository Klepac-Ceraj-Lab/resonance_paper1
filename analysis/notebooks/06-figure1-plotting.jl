# # Figure Plotting

include("../scripts/startup_loadpackages.jl")
using JLD2
using MakieLayout
using AbstractPlotting
using StatsMakie
using CairoMakie
using Makie
using ColorSchemes
using FileIO
using StatsBase: midpoints

AbstractPlotting.inline!(false)

@load "analysis/figures/assets/metadata.jld2" allmeta ubothmeta ukidsmeta allkidsmeta allmoms allkids umoms ukids oldkids uboth
@load "analysis/figures/assets/taxa.jld2" species speciesmds kidsspeciesmds kidsspeciesmdsaxes
@load "analysis/figures/assets/unirefs.jld2" unirefaccessorymds unirefaccessorymdsaxes kidsunirefaccessorymds kidsunirefaccessorymdsaxes
@load "analysis/figures/assets/otherfunctions.jld2" kos kosdiffs kosdm ecs ecsdm pfams pfamsdiffs pfamsdm
@load "analysis/figures/assets/permanovas.jld2" r2 r2m qa allpermanovas species_permanovas unirefaccessory_permanovas kos_permanovas pfams_permanovas
@load "analysis/figures/assets/fsea.jld2" allfsea mdcors
@load "analysis/figures/assets/difs.jld2" speciesdiffs unirefaccessorydiffs kosdiffs pfamsdiffs
@load "analysis/figures/assets/stratkos.jld2" stratkos

allfsea.median = map(median, allfsea.cors)
allmeta.cogAssessment = [x == "None" ? missing : x for x in allmeta.cogAssessment]
rename!(r2, :unirefaccessory=>:accessory)

# ## Figure 1

res=(7*300,5*300)
f1_scene, f1_layout = layoutscene(resolution=res, alignmode=Outside())
f1_scene

# ### Figure 1a
cohort_img = load("analysis/figures/img/cohort.png");
ratio_img = size(cohort_img)[1] / size(cohort_img)[2]

cohort_layout = GridLayout()
f1_layout[1,1] = cohort_layout

cohort = cohort_layout[1,1] = LAxis(f1_scene)
image!(cohort, rotr90(cohort_img)) # for some reason Makie plots images rotated
tightlimits!(cohort)
hidexdecorations!(cohort)
hideydecorations!(cohort)
colsize!(f1_layout, 1, Relative(0.7)) # need to fix this so Aspect with it can work
rowsize!(f1_layout, 1, Aspect(1, ratio_img))

cohort.bottomspinevisible = false
cohort.leftspinevisible = false
cohort.topspinevisible = false
cohort.rightspinevisible = false

# ### Figure 1b - Permanovas

phm_layout = GridLayout()
phm = phm_layout[1,1] = LAxis(f1_scene)
f1_layout[1,2] = phm_layout


phmyorder = [
    "subject",
    "subject type",
    "2+ subject type",
    "age",
    "2+ age",
    "child gender",
    "birth type",
    "breastfeeding",
    "mother SES",
    "BMI",
    "cognitive function",
    "neocortical",
    "subcortical",
    "limbic",
    "cerebellar"
]
phmysrt = reverse(invperm(sortperm(phmyorder)))

phmxorder = [
    "species",
    "accessory",
    "kos",
    "pfams"
]
phmxsrt = reverse(invperm(sortperm(phmxorder)))

 ## "BMI" is index 10
values = disallowmissing(r2m')[phmxsrt, phmysrt]
xrange = 0:size(values,1)
yrange = 0:size(values,2)
phm_plot = heatmap!(phm, xrange, yrange, values, colorrange=(0,0.21), colormap=:PuBu)

pixelcentervalues = [Point2f0(x, y)
    for x in midpoints(LinRange(xrange.start, xrange.stop, size(values, 1) + 1)),
        y in midpoints(LinRange(yrange.start, yrange.stop, size(values, 2) + 1)) .- 0.1]
function rect_to_rect(fromrect, torect, point)
    pfrac = (point .- fromrect.origin) ./ fromrect.widths
    pfrac .* torect.widths .+ torect.origin
end
pixelvals = lift(phm.limits, phm.scene.px_area) do lims, pxa
    vec(rect_to_rect.(Ref(lims), Ref(pxa), pixelcentervalues))
end
phm_labels = vec([string(v)[1:5] for v in values])
annotations!(f1_scene, phm_labels, pixelvals,
    align = (:center, :center),
    color = ifelse.(values .< 0.14, :black, :white),
    textsize = 16)

sig = vec(permutedims(replace(qa[phmysrt, phmxsrt], "" => " ")))
annotations!(f1_scene, sig, @lift($pixelvals .+ Ref(Point2f0(0, 10))),
    align = (:center, :center),
    color = ifelse.(values .< 0.14, :black, :white),
    textsize = 16)

# sigpixelvals = lift(axes_1E.limits, axes_1E.f1_scene.px_area) do lims, pxa
#     vec(rect_to_rect.(Ref(lims), Ref(pxa), pixelcentervalues .+ Ref(Point2f0(0.2, 0))))
# end
# annotations!(f1_scene, vec([v for v in sig]), sigpixelvals,
#     align = (:center, :center),
#     color = ifelse.(values .< 0.14, :black, :white),
#     textsize = 16)

tightlimits!(phm)

phm.yticks = (0.5:1:size(r2m,1) - 0.5, r2.label[phmysrt])
tight_yticklabel_spacing!(phm)

phm.xticks = (0.5:1:size(r2,2) - 1.5, string.(names(r2)[2:end][phmxsrt]))

phm_legend = LColorbar(f1_scene, phm_plot, width=30)
phm_legend.ticks = let r = range(0, stop=0.20, length=6)
    t = string.(r)
    t[end] = join([">", t[end]])
    (r,t)
end
phm_layout[1, 2] = phm_legend
phm_layout[1, 2, Left()] = LText(f1_scene, "% Variance", rotation = pi/2, padding = (0, 5, 0, 0))


# ### Figure 1cd

pcoas_layout = GridLayout()
taxpcoa = pcoas_layout[1,1]= LAxis(f1_scene)
funcpcoa = pcoas_layout[1,2]= LAxis(f1_scene)

f1_layout[2,1:2] = pcoas_layout

taxpcoa_plot = scatter!(taxpcoa, Group(marker=allkidsmeta.ageLabel), Style(color=allkidsmeta.shannon),
        projection(kidsspeciesmds)[:,1], allkidsmeta.correctedAgeDays ./ 365,
        markersize = 10 * AbstractPlotting.px, marker=[:utriangle, :rect, :circle],
        strokecolor=:black, strokewidth=1)
taxpcoa.xgridvisible = false
taxpcoa.xticksvisible=false
taxpcoa.xticklabelsvisible=false
taxpcoa.xlabelpadding=20
taxpcoa.xlabel = "MDS1 ($(round(kidsspeciesmdsaxes[1]*100, digits=2)) %)"

taxpcoa.ylabel = "Age (years)"
taxpcoa.ylabelpadding=20

age_markers = [
    MarkerElement(marker = :utriangle, color=:white, strokecolor=:black),
    MarkerElement(marker = :rect, color=:white, strokecolor=:black),
    MarkerElement(marker = :circle, color=:white, strokecolor=:black)]
age_labels = [
    "1 and under",
    "1 to 2",
    "2 and over"]

legend_1BC_markers = pcoas_layout[2, 1:2] = LLegend(
    f1_scene, age_markers, age_labels,
    orientation = :horizontal,
    titlevisible=false, patchcolor=:transparent, tellheight=true, height=Auto())


taxpcoa_plot_colorbar_legend = LColorbar(f1_scene, taxpcoa_plot, width=30)
taxpcoa_plot_colorbar_layout = gridnest!(pcoas_layout, 1, 1)
taxpcoa_plot_colorbar_layout[1, 2] = taxpcoa_plot_colorbar_legend
taxpcoa_plot_colorbar_layout[1, 2, Left()] = LText(f1_scene, "Shannon Index", rotation = pi/2, padding = (0, 5, 0, 0))

funcpcoa_plot = scatter!(funcpcoa, Group(marker=allkidsmeta.ageLabel), Style(color=allkidsmeta.n_unirefs), # identifiable_unirefs?
        projection(kidsunirefaccessorymds)[:,1], allkidsmeta.correctedAgeDays ./ 365,
        markersize = 10 * AbstractPlotting.px, marker=marker=[:utriangle, :rect, :circle],
        strokecolor=:black, strokewidth=1, colormap=:BrBG)

funcpcoa.xgridvisible = false
funcpcoa.xticksvisible=false
funcpcoa.xticklabelsvisible=false
funcpcoa.xlabelpadding=20
funcpcoa.xlabel = "MDS1 ($(round(kidsunirefaccessorymdsaxes[1]*100, digits=2)) %)"

funcpcoa.ylabel = "Age (years)"
funcpcoa.ylabelpadding=20

funcpcoa_plot_colorbar_legend = LColorbar(f1_scene, funcpcoa_plot, width=30)
funcpcoa_plot_colorbar_legend.tickformat = xs-> ["$(round(Int, x/1000))k" for x in xs]

funcpcoa_plot_layout = gridnest!(pcoas_layout, 1, 2)
funcpcoa_plot_layout[1, 2] = funcpcoa_plot_colorbar_legend
funcpcoa_plot_layout[1, 2, Left()] = LText(f1_scene, "Number of UniRef90s", rotation = pi/2, padding = (0, 5, 0, 0))

# ## Save Figure 1

cohort_layout[1, 1, TopLeft()] = LText(f1_scene, "a", textsize = 40, padding = (0, 0, 10, 0), halign=:left)
phm_layout[1, 1, TopLeft()] = LText(f1_scene, "b", textsize = 40, padding = (0, 0, 30, 0), halign=:left)
pcoas_layout[1, 1, TopLeft()] = LText(f1_scene, "c", textsize = 40, padding = (0, 0, 10, 0), halign=:left)
pcoas_layout[1, 2, TopLeft()] = LText(f1_scene, "d", textsize = 40, padding = (0, 0, 10, 0), halign=:left)

foreach(Union{LColorbar, LAxis}, f1_layout) do obj
    tight_ticklabel_spacing!(obj)
end

save("analysis/figures/figure1.jpg", f1_scene, resolution=res);
f1_scene

# ## Figure 2

f2_scene, f2_layout = layoutscene(resolution=res, alignmode=Outside())
f2_scene
# ### Heatmap and cognitive scores by age

cogage = f2_layout[1,1] = LAxis(f2_scene)

let filt = map(!ismissing, allkidsmeta.cogScore)
    x = disallowmissing(allkidsmeta.correctedAgeDays[filt] ./ 365)
    y = disallowmissing(allkidsmeta.cogScore[filt])
    g = disallowmissing(allkidsmeta.cogAssessment[filt])
    scatter!(cogage, Group(g), x, y,
                color=ColorSchemes.Set1_5.colors[2:end],
                markersize = 10 * AbstractPlotting.px,
                strokecolor=:black
                )

end
cogage.xlabel = "Age (years)"
cogage.ylabel = "Overall cognitive function"
cogage.xlabelpadding = 20
cogage.ylabelpadding = 20

legend_cogage = f2_layout[2,1] = LLegend(f2_scene,
    [MarkerElement(marker=:circle, color=ColorSchemes.Set1_7.colors[i], strokecolor=:black) for i in 2:5],
    string.(sort(unique(skipmissing(allkidsmeta.cogAssessment)))),
    titlevisible=false, patchcolor=:transparent, orientation = :horizontal, tellheight=true, height=Auto(), tellwidth=false)
f2_scene




# ## Figure 3

include("../scripts/stratified_functions.jl")

##
res = (Int(7.5*300), 6*300)
scene, layout = layoutscene(resolution = res)

fsea_layout = GridLayout(alignmode=Outside())
fsea_axes = fsea_layout[1, 1:5] = [LAxis(scene) for col in 1:5]

cs = copy(ColorSchemes.RdYlBu_9.colors)
gr = ColorSchemes.grays.colors[5]
cs = [cs[[1,2,4]]..., gr,cs[[end-2,end-1,end]]...]

fsea_legend = fsea_layout[2, 1:5] = LLegend(scene,
    [
        [MarkerElement(marker = :rect, color = cs[i], strokecolor = :black) for i in 1:3],
        [MarkerElement(marker = :rect, color = cs[4], strokecolor = :black)],
        [MarkerElement(marker = :rect, color = cs[i], strokecolor = :black) for i in 5:7],
    ],
    [
         ["q < 0.001", "q < 0.01", "q < 0.1"],
         ["NS"],
         ["q < 0.1", "q < 0.01", "q < 0.001"],
     ],
     ["median < 0", nothing, "median > 0"],
    titlevisible=false, orientation=:horizontal,
    patchcolor=:transparent, tellheight=true, height=Auto())

allfsea.color = map(eachrow(allfsea)) do row
    m = row.median
    q = row.qvalue
    c = cs[4]
    if m > 0
        if q < 0.001
            c = cs[end]
        elseif q < 0.01
            c = cs[end-1]
        elseif q < 0.1
            c = cs[end-2]
        end
    elseif m < 0
        if q < 0.001
            c = cs[1]
        elseif q < 0.01
            c = cs[2]
        elseif q < 0.1
            c = cs[3]
        end
    end
    c
end


allfsea2 = vcat(
    (DataFrame((geneset=row.geneset,
                metadatum=row.metadatum,
                cor=i,
                color=row.color,
                qvalue=row.qvalue
                ) for i in row.cors)
    for row in eachrow(allfsea))...
    )
allfsea2.geneset = map(allfsea2.geneset) do gs
    gs = replace(gs, r" \(.+\)"=>"")
    gs = replace(gs, r"^.+Estradiol"=>"Estradiol")
    gs = replace(gs, "degradation"=>"deg")
    gs = replace(gs, "synthesis"=>"synth")
    gs
end

siggs = filter(row-> row.anysig, by(allfsea2, :geneset) do gs
                (anysig = any(<(0.1), gs.qvalue),)
            end).geneset |> Set

filter!(row-> row.geneset in siggs, allfsea2)
sort!(allfsea2, :geneset, rev=true)
let genesets = unique(allfsea2.geneset)
    gmap = Dict(g=>i for (i,g) in enumerate(genesets))
    allfsea2.gsindex = [gmap[g] for g in allfsea2.geneset]
end

groups = groupby(allfsea2, :metadatum)

let ugs = unique(allfsea2.geneset)
    for (i, gr) in enumerate(groups[2:end])
        by(gr, :gsindex) do gs
            g = first(gs.geneset)
            x = gs.gsindex
            y = gs.cor
            c = first(gs.color)
            boxplot!(fsea_axes[i], x, y, color=c, orientation=:horizontal,
                markersize = 10 * AbstractPlotting.px, outliercolor=c)
        end
        fsea_axes[i].xlabel = first(gr.metadatum)
        fsea_axes[i].xlabelpadding = 20
        fsea_axes[i].yticks = (1:length(ugs), ugs)

        i !=1 && (fsea_axes[i].yticklabelsvisible = false; fsea_axes[i].yticksvisible = false)
    end
end

extr = extrema(allfsea2.cor)
for i in 1:5
    xlims!(fsea_axes[i], extr)
end
foreach(Union{LColorbar, LAxis}, fsea_layout) do obj
    tight_ticklabel_spacing!(obj)
end
layout[1,1] = fsea_layout
scene

## gluts, p1
stratfunc_layout=GridLayout(alignmode=Outside())

gluts_layout = GridLayout(alignmode=Outside())
p1ax = gluts_layout[1,1] = LAxis(scene)
p1ann = gluts_layout[2,1] = LAxis(scene, height=20)

p1 = barplot!(p1ax, Position.stack, Data(gluts), Group(:taxon), :x, :total, width=1, color=ColorBrewer.palette("Set1",8))
tightlimits!(p1ax)
hidexdecorations!(p1ax)
tight_yticklabel_spacing!(p1ax)
p1ax.ylabelpadding = 50
p1ax.ylabel = "Glutamate synthesis"

linkxaxes!(p1ax, p1ann)
tightlimits!(p1ann)
hidexdecorations!(p1ann)
hideydecorations!(p1ann)

p1leg_entries = map(uniquesorted(gluts.taxon)) do t
    t = lstrip(t)
    t = split(t, "_")
    length(t) == 2 ? t = "$(first(t[1])). $(t[2])" : t = String(t[1])
end

p1leg = gluts_layout[1,2] = LLegend(scene,
    [MarkerElement(color = p.attributes.color[], marker = :rect, strokecolor = :black) for p in p1.plots],
    p1leg_entries, "Species",
    patchcolor=:transparent)
for (l, c) in zip(unique(gluts.agelabel), ColorBrewer.palette("Set3", 3))
    (start, stop) = extrema(gluts[gluts.agelabel .== l, :x])
    poly!(p1ann, Point2f0[(start-0.5,0), (stop+0.5, 0), (stop+0.5, 1), (start-0.5, 1)], color = c)
end

# layout[1,1] = gluts_layout
# scene

## glutd, p2

glutd_layout = GridLayout(alignmode=Outside())
p2ax = glutd_layout[1,1] = LAxis(scene)
p2ann = glutd_layout[2,1] = LAxis(scene, height=20)

p2 = barplot!(p2ax, Position.stack, Data(glutd), Group(:taxon), :x, :total, width=1, color=ColorBrewer.palette("Set1",8))
tightlimits!(p2ax)
hidexdecorations!(p2ax)
tight_yticklabel_spacing!(p2ax)
p2ax.ylabelpadding = 40
p2ax.ylabel = "Glutamate degradation"

linkxaxes!(p2ax, p2ann)
tightlimits!(p2ann)
hidexdecorations!(p2ann)
hideydecorations!(p2ann)

p2leg_entries = map(uniquesorted(glutd.taxon)) do t
    t = lstrip(t)
    t = split(t, "_")
    length(t) == 2 ? t = "$(first(t[1])). $(t[2])" : t = String(t[1])
end

p2leg = glutd_layout[1,2] = LLegend(scene,
    [MarkerElement(color = p.attributes.color[], marker = :rect, strokecolor = :black) for p in p1.plots],
    p2leg_entries, "Species",
    patchcolor=:transparent)
for (l, c) in zip(unique(glutd.agelabel), ColorBrewer.palette("Set3", 3))
    (start, stop) = extrema(glutd[glutd.agelabel .== l, :x])
    poly!(p1ann, Point2f0[(start-0.5,0), (stop+0.5, 0), (stop+0.5, 1), (start-0.5, 1)], color = c)
end


for (l, c) in zip(unique(glutd.agelabel), ColorBrewer.palette("Set3", 3))
    (start, stop) = extrema(glutd[glutd.agelabel .== l, :x])
    poly!(p2ann, Point2f0[(start-0.5,0), (stop+0.5, 0), (stop+0.5, 1), (start-0.5, 1)], color = c)
end


## gabas, p3

gabas_layout = GridLayout(alignmode=Outside())
p3ax = gabas_layout[1,1] = LAxis(scene)
p3ann = gabas_layout[2,1] = LAxis(scene, height=20)

p3 = barplot!(p3ax, Position.stack, Data(gabas), Group(:taxon), :x, :total, width=1, color=ColorBrewer.palette("Set1",8))
tightlimits!(p3ax)
hidexdecorations!(p3ax)
tight_yticklabel_spacing!(p3ax)
p3ax.ylabelpadding = 40
p3ax.ylabel = "GABA synthesis"

linkxaxes!(p3ax, p3ann)
tightlimits!(p3ann)
hidexdecorations!(p3ann)
hideydecorations!(p3ann)

p3leg_entries = map(uniquesorted(gabas.taxon)) do t
    t = lstrip(t)
    t = split(t, "_")
    length(t) == 2 ? t = "$(first(t[1])). $(t[2])" : t = String(t[1])
end

p3leg = gabas_layout[1,2] = LLegend(scene,
    [MarkerElement(color = p.attributes.color[], marker = :rect, strokecolor = :black) for p in p1.plots],
    p3leg_entries, "Species",
    patchcolor=:transparent)
for (l, c) in zip(unique(gabas.agelabel), ColorBrewer.palette("Set3", 3))
    (start, stop) = extrema(gabas[gabas.agelabel .== l, :x])
    poly!(p1ann, Point2f0[(start-0.5,0), (stop+0.5, 0), (stop+0.5, 1), (start-0.5, 1)], color = c)
end


for (l, c) in zip(unique(gabas.agelabel), ColorBrewer.palette("Set3", 3))
    (start, stop) = extrema(gabas[gabas.agelabel .== l, :x])
    poly!(p3ann, Point2f0[(start-0.5,0), (stop+0.5, 0), (stop+0.5, 1), (start-0.5, 1)], color = c)
end

## gabad, p4

gabad_layout = GridLayout(alignmode=Outside())
p4ax = gabad_layout[1,1] = LAxis(scene)
p4ann = gabad_layout[2,1] = LAxis(scene, height=20)

p4 = barplot!(p4ax, Position.stack, Data(gabad), Group(:taxon), :x, :total, width=1, color=ColorBrewer.palette("Set1",8))
tightlimits!(p4ax)
hidexdecorations!(p4ax)
tight_yticklabel_spacing!(p4ax)
p4ax.ylabelpadding = 50
p4ax.ylabel = "GABA degradation"

linkxaxes!(p4ax, p4ann)
tightlimits!(p4ann)
hidexdecorations!(p4ann)
hideydecorations!(p4ann)

p1leg_entries = map(uniquesorted(gluts.taxon)) do t
    t = lstrip(t)
    t = split(t, "_")
    length(t) == 2 ? t = "$(first(t[1])). $(t[2])" : t = String(t[1])
end

p4leg = gabad_layout[1,2] = LLegend(scene,
    [MarkerElement(color = p.attributes.color[], marker = :rect, strokecolor = :black) for p in p1.plots],
    p1leg_entries, "Species",
    patchcolor=:transparent)
for (l, c) in zip(unique(gabad.agelabel), ColorBrewer.palette("Set3", 3))
    (start, stop) = extrema(gabad[gabad.agelabel .== l, :x])
    poly!(p1ann, Point2f0[(start-0.5,0), (stop+0.5, 0), (stop+0.5, 1), (start-0.5, 1)], color = c)
end


for (l, c) in zip(unique(gabad.agelabel), ColorBrewer.palette("Set3", 3))
    (start, stop) = extrema(gabad[gabad.agelabel .== l, :x])
    poly!(p4ann, Point2f0[(start-0.5,0), (stop+0.5, 0), (stop+0.5, 1), (start-0.5, 1)], color = c)
end

p4leg.attributes.label[] = "Species"

##
stratfunc_layout[1:2, 1:2] = [gabas_layout gabad_layout;
                              gluts_layout glutd_layout]

layout[2, 1] = stratfunc_layout

agelegend = layout[3,1] = LLegend(scene, orientation=:horizontal,
                                    [MarkerElement(color=c, marker=:rect, strokecolor=:black) for c in ColorBrewer.palette("Set3", 3)],
                                    collect(uniquesorted(gabad.agelabel)), patchcolor=:transparent, tellwidth=false, width=Auto(), tellheight=true,
                                    height=Auto())
agelegend.attributes.label[] = "Age"


fsea_layout[1, 1, TopLeft()] = LText(scene, "a", textsize = 40, padding = (-20, 0, 20, 0), halign=:left)
gabas_layout[1, 1, TopLeft()] = LText(scene, "b", textsize = 40, padding = (-20, 0, 20, 0), halign=:left)
gabad_layout[1, 1, TopLeft()] = LText(scene, "c", textsize = 40, padding = (-20, 0, 20, 0), halign=:left)
gluts_layout[1, 1, TopLeft()] = LText(scene, "d", textsize = 40, padding = (-20, 0, 20, 0), halign=:left)
glutd_layout[1, 1, TopLeft()] = LText(scene, "e", textsize = 40, padding = (-20, 0, 20, 0), halign=:left)
# save("/Users/ksb/Desktop/test.jpg", scene, resolution=res);
save("analysis/figures/figure2.jpg", scene, resolution=res);
scene

# ## Scratch

CairoMakie.activate!(type = "svg")
scene, layout = layoutscene()
plt = layout[1,1] = LAxis(scene)
scatter!(plt, rand(10), rand(10), markersize=AbstractPlotting.px*10)
scene
save("/Users/ksb/Desktop/test.pdf", f1_scene);