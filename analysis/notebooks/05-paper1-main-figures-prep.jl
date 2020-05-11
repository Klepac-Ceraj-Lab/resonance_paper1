# # Main Figures
#
# Start after notebook 2.
#
# ## Setup
#
# This step takes about an hour

include("../scripts/startup_loadall.jl")
## Figure 1A-B
speciesdm = pairwise(BrayCurtis(), species)
speciesmds = fit(MDS, speciesdm, distances=true)
speciesmdsaxes = [v / sum(eigvals(speciesmds)) for v in eigvals(speciesmds)]

kidsspeciesmds = fit(MDS, speciesdm[allkids,allkids], distances=true)
kidsspeciesmdsaxes = [v / sum(eigvals(kidsspeciesmds)) for v in eigvals(kidsspeciesmds)]

# ## Figure 1C-D

unirefaccessorydm = pairwise(BrayCurtis(), unirefaccessory)
unirefaccessorymds = fit(MDS, unirefaccessorydm[uboth, uboth], distances=true)
unirefaccessorymdsaxes = [v / sum(eigvals(unirefaccessorymds)) for v in eigvals(unirefaccessorymds)]

kidsunirefaccessorymds = fit(MDS, unirefaccessorydm[allkids,allkids], distances=true)
kidsunirefaccessorymdsaxes = [v / sum(eigvals(kidsunirefaccessorymds)) for v in eigvals(kidsunirefaccessorymds)]

# ## Figure 1E

species_permanovas = vcat(
    permanova(speciesdm, string.(allmeta.subject), label="subject"),
    permanova(speciesdm[uboth,uboth], ubothmeta.subject_type, label="subject type"),
    permanova(speciesdm[uboth,uboth], ubothmeta,
        datafilter=row-> in(row.ageLabel, ("2 and over", "mom")),
        fields=[:subject_type], label="2+ subject type"),
    permanova(speciesdm[ukids,ukids], ukidsmeta.correctedAgeDays, label="age"),
    permanova(speciesdm[ukids,ukids], ukidsmeta,
        datafilter=row-> in(row.ageLabel, ("2 and over", "mom")),
        fields=[:correctedAgeDays], label="2+ age"),
    permanova(speciesdm[ukids,ukids], string.(ukidsmeta.birthType), label="birth type"),
    permanova(speciesdm[ukids,ukids], string.(ukidsmeta.childGender), datafilter=x-> x != "Don't know", label="child gender"),
    permanova(speciesdm[ukids,ukids], ukidsmeta.mother_HHS, label="mother SES"),
    permanova(speciesdm[ukids,ukids], ukidsmeta, fields=[:correctedAgeDays,:limbic_normed], label="limbic")[2:2,:],
    permanova(speciesdm[ukids,ukids], ukidsmeta, fields=[:correctedAgeDays,:subcortical_normed], label="subcortical")[2:2,:],
    permanova(speciesdm[ukids,ukids], ukidsmeta, fields=[:correctedAgeDays,:neocortical_normed], label="neocortical")[2:2,:],
    permanova(speciesdm[ukids,ukids], ukidsmeta, fields=[:correctedAgeDays,:cerebellar_normed], label="cerebellar")[2:2,:],
    permanova(speciesdm[ukids,ukids], ukidsmeta.cogScore, label="cognitive function"),
    permanova(speciesdm[ukids,ukids], ukidsmeta.breastfeeding, label="breastfeeding"),
    permanova(speciesdm[ukids,ukids], ukidsmeta.simple_race, label="race")
    # permanova(speciesdm[ukids,ukids], ukidsmeta.BMI_calc, label="BMI")
    )
filter!(r-> !ismissing(r[Symbol("Pr(>F)")]), species_permanovas)
species_permanovas[!, :feature] .= "species"
rename!(species_permanovas, Symbol("Pr(>F)")=>:p_value)
disallowmissing!(species_permanovas)
species_permanovas.q_value = adjust(species_permanovas.p_value, BenjaminiHochberg())
sort!(species_permanovas, :q_value)

##
unirefaccessory_permanovas = vcat(
    permanova(unirefaccessorydm, string.(allmeta.subject), label="subject"),
    permanova(unirefaccessorydm[uboth,uboth], ubothmeta.subject_type, label="subject type"),
    permanova(unirefaccessorydm[uboth,uboth], ubothmeta,
        datafilter=row-> in(row.ageLabel, ("2 and over", "mom")),
        fields=[:subject_type], label="2+ subject type"),
    permanova(unirefaccessorydm[ukids,ukids], ukidsmeta.correctedAgeDays, label="age"),
    permanova(unirefaccessorydm[ukids,ukids], ukidsmeta,
        datafilter=row-> in(row.ageLabel, ("2 and over", "mom")),
        fields=[:correctedAgeDays], label="2+ age"),
    permanova(unirefaccessorydm[ukids,ukids], string.(ukidsmeta.birthType), label="birth type"),
    permanova(unirefaccessorydm[ukids,ukids], string.(ukidsmeta.childGender), datafilter=x-> x != "Don't know", label="child gender"),
    permanova(unirefaccessorydm[ukids,ukids], ukidsmeta.mother_HHS, label="mother SES"),
    permanova(unirefaccessorydm[ukids,ukids], ukidsmeta, fields=[:correctedAgeDays,:limbic_normed], label="limbic")[2:2,:],
    permanova(unirefaccessorydm[ukids,ukids], ukidsmeta, fields=[:correctedAgeDays,:subcortical_normed], label="subcortical")[2:2,:],
    permanova(unirefaccessorydm[ukids,ukids], ukidsmeta, fields=[:correctedAgeDays,:neocortical_normed], label="neocortical")[2:2,:],
    permanova(unirefaccessorydm[ukids,ukids], ukidsmeta, fields=[:correctedAgeDays,:cerebellar_normed], label="cerebellar")[2:2,:],
    permanova(unirefaccessorydm[ukids,ukids], ukidsmeta.cogScore, label="cognitive function"),
    permanova(unirefaccessorydm[ukids,ukids], ukidsmeta.breastfeeding, label="breastfeeding"),
    permanova(unirefaccessorydm[ukids,ukids], ukidsmeta.simple_race, label="race")
    # permanova(unirefaccessorydm[ukids,ukids], ukidsmeta.BMI_calc, label="BMI")
    )

filter!(r-> !ismissing(r[Symbol("Pr(>F)")]), unirefaccessory_permanovas)
unirefaccessory_permanovas[!, :feature] .= "unirefaccessory"
rename!(unirefaccessory_permanovas, Symbol("Pr(>F)")=>:p_value)
disallowmissing!(unirefaccessory_permanovas)
unirefaccessory_permanovas.q_value = adjust(unirefaccessory_permanovas.p_value, BenjaminiHochberg())
sort!(unirefaccessory_permanovas, :q_value)

##
pfamsdm = pairwise(BrayCurtis(), pfams)
kosdm = pairwise(BrayCurtis(), kos)
ecsdm = pairwise(BrayCurtis(), ecs)
pfams_permanovas = vcat(
    permanova(pfamsdm, string.(allmeta.subject), label="subject"),
    permanova(pfamsdm[uboth,uboth], ubothmeta.subject_type, label="subject type"),
    permanova(pfamsdm[uboth,uboth], ubothmeta,
        datafilter=row-> in(row.ageLabel, ("2 and over", "mom")),
        fields=[:subject_type], label="2+ subject type"),
    permanova(pfamsdm[ukids,ukids], ukidsmeta.correctedAgeDays, label="age"),
    permanova(pfamsdm[ukids,ukids], ukidsmeta,
        datafilter=row-> in(row.ageLabel, ("2 and over", "mom")),
        fields=[:correctedAgeDays], label="2+ age"),
    permanova(pfamsdm[ukids,ukids], string.(ukidsmeta.birthType), label="birth type"),
    permanova(pfamsdm[ukids,ukids], string.(ukidsmeta.childGender), datafilter=x-> x != "Don't know", label="child gender"),
    permanova(pfamsdm[ukids,ukids], ukidsmeta.mother_HHS, label="mother SES"),
    permanova(pfamsdm[ukids,ukids], ukidsmeta, fields=[:correctedAgeDays,:limbic_normed], label="limbic")[2:2,:],
    permanova(pfamsdm[ukids,ukids], ukidsmeta, fields=[:correctedAgeDays,:subcortical_normed], label="subcortical")[2:2,:],
    permanova(pfamsdm[ukids,ukids], ukidsmeta, fields=[:correctedAgeDays,:neocortical_normed], label="neocortical")[2:2,:],
    permanova(pfamsdm[ukids,ukids], ukidsmeta, fields=[:correctedAgeDays,:cerebellar_normed], label="cerebellar")[2:2,:],
    permanova(pfamsdm[ukids,ukids], ukidsmeta.cogScore, label="cognitive function"),
    permanova(pfamsdm[ukids,ukids], ukidsmeta.breastfeeding, label="breastfeeding"),
    permanova(pfamsdm[ukids,ukids], ukidsmeta.simple_race, label="race")
    # permanova(pfamsdm[ukids,ukids], ukidsmeta.BMI_calc, label="BMI")
    )

filter!(r-> !ismissing(r[Symbol("Pr(>F)")]), pfams_permanovas)
pfams_permanovas[!, :feature] .= "pfams"
rename!(pfams_permanovas, Symbol("Pr(>F)")=>:p_value)
disallowmissing!(pfams_permanovas)
pfams_permanovas.q_value = adjust(pfams_permanovas.p_value, BenjaminiHochberg())
sort!(pfams_permanovas, :q_value)
##
kos_permanovas = vcat(
    permanova(kosdm, string.(allmeta.subject), label="subject"),
    permanova(kosdm[uboth,uboth], ubothmeta.subject_type, label="subject type"),
    permanova(kosdm[uboth,uboth], ubothmeta,
        datafilter=row-> in(row.ageLabel, ("2 and over", "mom")),
        fields=[:subject_type], label="2+ subject type"),
    permanova(kosdm[ukids,ukids], ukidsmeta.correctedAgeDays, label="age"),
    permanova(kosdm[ukids,ukids], ukidsmeta,
        datafilter=row-> in(row.ageLabel, ("2 and over", "mom")),
        fields=[:correctedAgeDays], label="2+ age"),
    permanova(kosdm[ukids,ukids], string.(ukidsmeta.birthType), label="birth type"),
    permanova(kosdm[ukids,ukids], string.(ukidsmeta.childGender), datafilter=x-> x != "Don't know", label="child gender"),
    permanova(kosdm[ukids,ukids], ukidsmeta.mother_HHS, label="mother SES"),
    permanova(kosdm[ukids,ukids], ukidsmeta, fields=[:correctedAgeDays,:limbic_normed], label="limbic")[2:2,:],
    permanova(kosdm[ukids,ukids], ukidsmeta, fields=[:correctedAgeDays,:subcortical_normed], label="subcortical")[2:2,:],
    permanova(kosdm[ukids,ukids], ukidsmeta, fields=[:correctedAgeDays,:neocortical_normed], label="neocortical")[2:2,:],
    permanova(kosdm[ukids,ukids], ukidsmeta, fields=[:correctedAgeDays,:cerebellar_normed], label="cerebellar")[2:2,:],
    permanova(kosdm[ukids,ukids], ukidsmeta.cogScore, label="cognitive function"),
    permanova(kosdm[ukids,ukids], ukidsmeta.breastfeeding, label="breastfeeding"),
    permanova(kosdm[ukids,ukids], ukidsmeta.simple_race, label="race")
    # permanova(kosdm[ukids,ukids], ukidsmeta.BMI_calc, label="BMI")
    )

filter!(r-> !ismissing(r[Symbol("Pr(>F)")]), kos_permanovas)
kos_permanovas[!, :feature] .= "kos"
rename!(kos_permanovas, Symbol("Pr(>F)")=>:p_value)
disallowmissing!(kos_permanovas)
kos_permanovas.q_value = adjust(kos_permanovas.p_value, BenjaminiHochberg())
sort!(kos_permanovas, :q_value)

##
allpermanovas = vcat(
    species_permanovas,
    unirefaccessory_permanovas,
    pfams_permanovas,
    kos_permanovas
    )
sort!(allpermanovas, :R2)
r2 = unstack(allpermanovas, :label, :feature, :R2)
r2m = Matrix(r2[!,[:species, :unirefaccessory, :pfams, :kos]])
q = unstack(allpermanovas, :label, :feature, :q_value)
qm = Matrix(q[!,[:species, :unirefaccessory, :pfams, :kos]])

qa = let M = fill("", size(qm))
    for i in eachindex(qm)
        ismissing(qm[i]) && continue
        if qm[i] < 0.001
            M[i] = "***"
        elseif qm[i] < 0.01
            M[i] = "**"
        elseif qm[i] < 0.1
            M[i] = "*"
        end
    end
    M
end


## Figure 1G

abxr = CSV.read("data/uniprot/uniprot-abxr.tsv")
carbs = CSV.read("data/uniprot/uniprot-carbohydrate.tsv")
fa = CSV.read("data/uniprot/uniprot-fa.tsv")
unirefnames = map(u-> match.(r"UniRef90_(\w+)",u).captures[1], featurenames(unirefaccessory))

neuroactive = getneuroactive(unirefnames) # function in accessories.jl

allneuroactive = union([neuroactive[k] for k in keys(neuroactive)]...)

metadatums = [:correctedAgeDays,
              :cogScore,
              :neocortical_normed,
              :subcortical_normed,
              :limbic_normed,
              :cerebellar_normed]

allfsea = DataFrame(
            geneset   = String[],
            metadatum = String[],
            median    = Float64[],
            pvalue    = Float64[],
            cors      = Vector{Float64}[])

mdcors = Dict(m=>Float64[] for m in metadatums)

for md in metadatums
    @info "Working on $md"
    filt = map(!ismissing, ukidsmeta[!,md])
    cors = cor(ukidsmeta[filt, md], occurrences(view(unirefaccessory, sites=ukids))[:,filt], dims=2)'
    mdcors[md] = filter(!isnan, cors)
    for (key, pos) in pairs(neuroactive)
        allcors = filter(!isnan, cors[pos])
        notcors = filter(!isnan, cors[Not(pos)])
        length(allcors) < 4 && continue
        @info "    $key"
        mwu = MannWhitneyUTest(allcors, notcors)
        m = median(allcors)
        p = pvalue(mwu)
        push!(allfsea, (geneset=key, metadatum=String(md), median=m, pvalue=p, cors=allcors))
    end
end

allfsea.qvalue = adjust(allfsea.pvalue, BenjaminiHochberg())

# ## Supplementary Figure 1

function labeldiff(dm, labels)
    u = sort(unique(labels))
    d = Dict(u1 => Dict() for u1 in u)
    for (l1 , l2) in multiset_permutations(repeat(u,2), 2)

        l1pos = findall(isequal(l1), labels)
        l2pos = findall(isequal(l2), labels)
        ds = vec(dm[l1pos, l2pos])
        d[l1][l2] = ds
    end
    d
end


speciesdiffs = labeldiff(speciesdm[uboth, uboth], allmeta.ageLabel[uboth])
unirefaccessorydiffs = labeldiff(unirefaccessorydm[uboth,uboth], allmeta.ageLabel[uboth])
pfamsdiffs = labeldiff(pfamsdm[uboth,uboth], allmeta.ageLabel[uboth])
kosdiffs = labeldiff(kosdm[uboth,uboth], allmeta.ageLabel[uboth])

# ## Exports

using JLD2

@assert sitenames(species) == allmeta.sample
allmeta.pcopri = collect(vec(occurrences(view(species, species=["Prevotella_copri"]))))

@save "analysis/figures/assets/metadata.jld2" allmeta ubothmeta ukidsmeta allkidsmeta allmoms allkids umoms ukids oldkids uboth
@save "analysis/figures/assets/taxa.jld2" species speciesmds kidsspeciesmds kidsspeciesmdsaxes
@save "analysis/figures/assets/unirefs.jld2" unirefaccessorymds unirefaccessorymdsaxes kidsunirefaccessorymds kidsunirefaccessorymdsaxes
@save "analysis/figures/assets/otherfunctions.jld2" kos kosdiffs kosdm ecs ecsdm pfams pfamsdiffs pfamsdm
@save "analysis/figures/assets/permanovas.jld2" r2 r2m qa allpermanovas species_permanovas unirefaccessory_permanovas kos_permanovas pfams_permanovas
@save "analysis/figures/assets/fsea.jld2" allfsea mdcors
@save "analysis/figures/assets/difs.jld2" speciesdiffs unirefaccessorydiffs kosdiffs pfamsdiffs
