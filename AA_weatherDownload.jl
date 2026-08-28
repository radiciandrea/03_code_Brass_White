# code to download and elaborate weather data from meteofrance

using Downloads, CSV, DataFrames, Dates, CodecZlib, Statistics

# site data data:
sitesDF = DataFrame(
weatherStation = ["MONTPELLIER-AEROPORT", "MONTARNAUD", "MONTPELLIER-ENSAM"],
dep = ["34", "34", "34"],
site = ["PEROLS", "MONTARNAUD", "MONTPELLIER"], 
Hkm2 = [1429, 5195, 2564]) # which is Montpellier

# destination folder
path1 = "C:/Users/2024ar003/Desktop/Alcuni file permanenti/Post_doc_biodivecity/Dati/MeteoFrance"
path2 = "C:/Users/2024ar003/Desktop/Alcuni file permanenti/Post_doc_biodivecity/Code/03_code_Brass_White/data/weather"

deps = unique(sitesDF.dep)

# download

for di in 1:length(deps)
    
    #recent R+T+Wind 
    url = string("https://object.files.data.gouv.fr/meteofrance/data/synchro_ftp/BASE/QUOT/Q_", sitesDF.dep[1], "_latest-2025-2026_RR-T-Vent.csv.gz")
    dest = joinpath(path1, string("dpt_", sitesDF.dep[di], "_2025-2026_RR-T-Vent.csv.gz"))
    Downloads.download(url, dest)

    #recent other_parameters
    url = string("https://object.files.data.gouv.fr/meteofrance/data/synchro_ftp/BASE/QUOT/Q_", sitesDF.dep[1], "_latest-2025-2026_autres-parametres.csv.gz")
    dest = joinpath(path1, string("dpt_", sitesDF.dep[di], "_2025-2026_autres-parametres.csv.gz"))
    Downloads.download(url, dest)

    #old R+T+Wind
    url = string("https://object.files.data.gouv.fr/meteofrance/data/synchro_ftp/BASE/QUOT/Q_", sitesDF.dep[1], "_previous-1950-2024_RR-T-Vent.csv.gz")
    dest = joinpath(path1, string("dpt_", sitesDF.dep[di], "_1950_2024_RR-T-Vent.csv.gz"))
    Downloads.download(url, dest)

    #old other_parameters
    url = string("https://object.files.data.gouv.fr/meteofrance/data/synchro_ftp/BASE/QUOT/Q_", sitesDF.dep[1], "_previous-1950-2024_autres-parametres.csv.gz")
    dest = joinpath(path1, string("dpt_", sitesDF.dep[di], "_1950_2024_autres-parametres.csv.gz"))
    Downloads.download(url, dest)
end

# elaborate

for si in 1:nrow(sitesDF)

    println(si)

    site = sitesDF.site[si]
    weatherStation = sitesDF.weatherStation[si]

    #years (write it here otherwiise doesn't work)
    years = 2010:2025

    #2025 T, R

    filepath = string(path1, "/dpt_", sitesDF.dep[si], "_2025-2026_RR-T-Vent.csv.gz")

    df_meteofrance_2025 = CSV.File(
            GzipDecompressorStream(open(filepath));
            delim = ';',
            missingstring = "",
        ) |> DataFrame

    #foreach(println, x)
    #foreach(println, unique(df_meteofrance_2025.NOM_USUEL))

    df_meteofrance_2025 = filter(row -> row.NOM_USUEL == weatherStation, df_meteofrance_2025)

    # extract lon et _lat
    lat = df_meteofrance_2025.LAT[1]
    lon = df_meteofrance_2025.LON[1]
    alt = df_meteofrance_2025.ALTI[1]

    df_meteofrance_2025.date  = Date.(string.(df_meteofrance_2025.AAAAMMJJ), dateformat"yyyymmdd")
    df_meteofrance_2025.year  = Year.(df_meteofrance_2025.date)
    df_meteofrance_2025 = filter(row -> row.year <= Year(maximum(years)), df_meteofrance_2025)
    df_meteofrance_2025 = combine(
        groupby(df_meteofrance_2025, [:NOM_USUEL, :date, :year]),
        :RR => (x -> sum(skipmissing(x))) => :prec,
        :TM => (x -> mean(skipmissing(x))) => :tas,
        :TN => (x -> mean(skipmissing(x))) => :tasMin,
        :TX => (x -> mean(skipmissing(x))) => :tasMax,
    )

    rename!(df_meteofrance_2025, :NOM_USUEL => :site)

    #2025 other variables

    filepath = string(path1, "/dpt_", sitesDF.dep[si], "_2025-2026_autres-parametres.csv.gz")

    df_meteofrance_2025_2 = CSV.File(
            GzipDecompressorStream(open(filepath));
            delim = ';',
            missingstring = "",
        ) |> DataFrame

    df_meteofrance_2025_2 = filter(row -> row.NOM_USUEL == weatherStation, df_meteofrance_2025_2)
    df_meteofrance_2025_2.date  = Date.(string.(df_meteofrance_2025_2.AAAAMMJJ), dateformat"yyyymmdd")
    df_meteofrance_2025_2.year  = Year.(df_meteofrance_2025_2.date)
    df_meteofrance_2025_2 = filter(row -> row.year <= Year(maximum(years)), df_meteofrance_2025_2)
    df_meteofrance_2025_2 = combine(
        groupby(df_meteofrance_2025_2, [:NOM_USUEL, :date, :year]),
        :ETPMON => (x -> sum(skipmissing(x))) => :ETP,
        :UM => (x -> sum(skipmissing(x))) => :RH,
    )

    rename!(df_meteofrance_2025_2, :NOM_USUEL => :site)

    #cbind
    df_meteofrance_2025.ETP .= df_meteofrance_2025_2.ETP
    df_meteofrance_2025.RH .= df_meteofrance_2025_2.RH

    # ... -> 2024 R, T

    filepath = string(path1, "/dpt_", sitesDF.dep[si], "_1950_2024_RR-T-Vent.csv.gz")

    df_meteofrance_pre2025 = CSV.File(
            GzipDecompressorStream(open(filepath));
            delim = ';',
            missingstring = "",
        ) |> DataFrame

    df_meteofrance_pre2025 = filter(row -> row.NOM_USUEL == weatherStation, df_meteofrance_pre2025)
    df_meteofrance_pre2025.date  = Date.(string.(df_meteofrance_pre2025.AAAAMMJJ), dateformat"yyyymmdd")
    df_meteofrance_pre2025.year  = Year.(df_meteofrance_pre2025.date)
    df_meteofrance_pre2025 = filter(row -> row.year >= Year(minimum(years)), df_meteofrance_pre2025)
    df_meteofrance_pre2025 = combine(
        groupby(df_meteofrance_pre2025, [:NOM_USUEL, :date, :year]),
        :RR => (x -> sum(skipmissing(x))) => :prec,
        :TM => (x -> mean(skipmissing(x))) => :tas,
        :TN => (x -> mean(skipmissing(x))) => :tasMin,
        :TX => (x -> mean(skipmissing(x))) => :tasMax,
    )

    rename!(df_meteofrance_pre2025, :NOM_USUEL => :site)

    # ... -> 2024 other variables

    filepath = string(path1, "/dpt_", sitesDF.dep[si], "_1950_2024_autres-parametres.csv.gz")

    df_meteofrance_pre2025_2 = CSV.File(
            GzipDecompressorStream(open(filepath));
            delim = ';',
            missingstring = "",
        ) |> DataFrame

    df_meteofrance_pre2025_2 = filter(row -> row.NOM_USUEL == weatherStation, df_meteofrance_pre2025_2)
    df_meteofrance_pre2025_2.date  = Date.(string.(df_meteofrance_pre2025_2.AAAAMMJJ), dateformat"yyyymmdd")
    df_meteofrance_pre2025_2.year  = Year.(df_meteofrance_pre2025_2.date)
    df_meteofrance_pre2025_2 = filter(row -> row.year >= Year(minimum(years)), df_meteofrance_pre2025_2)
    df_meteofrance_pre2025_2 = combine(
        groupby(df_meteofrance_pre2025_2, [:NOM_USUEL, :date, :year]),
        :ETPMON => (x -> sum(skipmissing(x))) => :ETP,
        :UM => (x -> sum(skipmissing(x))) => :RH,
    )

    rename!(df_meteofrance_pre2025_2, :NOM_USUEL => :site)

    #cbind + rbind
    df_meteofrance_pre2025.ETP .= df_meteofrance_pre2025_2.ETP
    df_meteofrance_pre2025.RH .= df_meteofrance_pre2025_2.RH

    df_meteofrance = [df_meteofrance_pre2025; df_meteofrance_2025]
    # df_meteofrance = append(df_meteofrance_pre2025, df_meteofrance_2025)

    df_meteofrance[!, :lat] = fill(lat, size(df_meteofrance,1))
    df_meteofrance[!, :lon] = fill(lon, size(df_meteofrance,1))
    df_meteofrance[!, :alt] = fill(alt, size(df_meteofrance,1))

    # correction (e.g. for Montarnaud) and hourly computation (later)
    for i in 1:nrow(df_meteofrance)
        if isnan(df_meteofrance.tas[i])
            df_meteofrance.tas[i] = 0.5 *(df_meteofrance.tasMax[i] + df_meteofrance.tasMin[i])
        end

        if isnan(df_meteofrance.tasMax[i])
            df_meteofrance.tasMax[i] = 2*df_meteofrance.tas[i] - df_meteofrance.tasMin[i]
        end

        if isnan(df_meteofrance.tasMin[i])
            df_meteofrance.tasMin[i] = 2*df_meteofrance.tas[i] - df_meteofrance.tasMax[i]
        end

        if isnan(df_meteofrance.prec[i]) & i > 1
            df_meteofrance.prec[i] = df_meteofrance.prec[i-1]
        elseif   isnan(df_meteofrance.prec[i] == "NaN") & i == 1
            df_meteofrance.prec[i] = 0
        end

        if isnan(df_meteofrance.RH[i]) & i > 1
            df_meteofrance.RH[i] = df_meteofrance.RH[i-1]
        end
        
        if isnan(df_meteofrance.ETP[i]) & i > 1
            df_meteofrance.ETP[i] = df_meteofrance.ETP[i-1]
        end

    end
    

    for y in years
        df_meteofrance_y = filter(row -> row.year == Year(y), df_meteofrance)
        CSV.write(string(path2, "/Meteo_", site, "_", y, ".csv"), df_meteofrance_y)
    end
end

