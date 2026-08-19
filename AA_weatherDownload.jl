# code to download and elaborate weather data from meteofrance

using Downloads, CSV, DataFrames, Dates, CodecZlib, Statistics

# site data data:
sitesDF = DataFrame(
weatherStation = ["MONTPELLIER-AEROPORT", "MONTARNAUD", "MONTPELLIER-ENSAM"],
dep = ["34", "34", "34"],
site = ["PEROLS", "MONTARNAUD", "MONTPELLIER"], 
Hkm2 = [1429, 5195, 2564]) # which is Montpellier


# destination folder
path = "C:/Users/2024ar003/Desktop/Alcuni file permanenti/Post_doc_biodivecity/Code/01_code_Metelmann/data"

deps = unique(sitesDF.dep)

# download

for di in 1:length(deps)
    
    #recent data
    url = string("https://object.files.data.gouv.fr/meteofrance/data/synchro_ftp/BASE/QUOT/Q_", sitesDF.dep[1], "_latest-2025-2026_RR-T-Vent.csv.gz")
    dest = joinpath(path, string("dpt_", sitesDF.dep[di], "_2025-2026_RR-T-Vent.csv.gz"))

    Downloads.download(url, dest)

    #old data
    url = string("https://object.files.data.gouv.fr/meteofrance/data/synchro_ftp/BASE/QUOT/Q_", sitesDF.dep[1], "_previous-1950-2024_RR-T-Vent.csv.gz")
    dest = joinpath(path, string("dpt_", sitesDF.dep[di], "_1950_2024_RR-T-Vent.csv.gz"))

    Downloads.download(url, dest)
end

# elaborate

for si in 1:nrow(sitesDF)

    site = sitesDF.site[si]
    weatherStation = sitesDF.weatherStation[si]

    #years (write it here otherwiise doesn't work)
    years = 2010:2025

    #2025

    filepath = string(path, "/dpt_", sitesDF.dep[si], "_2025-2026_RR-T-Vent.csv.gz")

    df_meteofrance_2025 = CSV.File(
            GzipDecompressorStream(open(filepath));
            delim = ';',
            missingstring = "",
        ) |> DataFrame

    #foreach(println, x)
    #foreach(println, unique(df_meteofrance_2025.NOM_USUEL))

    # extract lon et _lat
    lat = df_meteofrance_2025.LAT[1]
    lon = df_meteofrance_2025.LON[1]

    df_meteofrance_2025 = filter(row -> row.NOM_USUEL == weatherStation, df_meteofrance_2025)
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

    # 2020 -> 2024

    filepath = string(path, "/dpt_", sitesDF.dep[si], "_1950_2024_RR-T-Vent.csv.gz")

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


    df_meteofrance = [df_meteofrance_pre2025; df_meteofrance_2025]
    # df_meteofrance = append(df_meteofrance_pre2025, df_meteofrance_2025)

    df_meteofrance[!, :lat] = fill(lat, size(df_meteofrance,1))
    df_meteofrance[!, :lon] = fill(lon, size(df_meteofrance,1))
    df_meteofrance[!, :H] = fill(sitesDF.Hkm2[1], size(df_meteofrance,1))

    # correction (e.g. for Montarnaud) and houlry computation (later)
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
       
    end
    

    for y in years
        df_meteofrance_y = filter(row -> row.year == Year(y), df_meteofrance)
        CSV.write(string("data/Meteo_", site, "_", y, ".csv"), df_meteofrance_y)
    end
end

