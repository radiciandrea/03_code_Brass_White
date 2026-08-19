# code to elaborate obs data from Grabels collection

using DataFrames, Dates, XLSX, TidierData, Plots, CSV

path = "C:/Users/2024ar003/Desktop/Alcuni file permanenti/Post_doc_biodivecity/Dati/Grabels"

# note PP: 4X = Valsière, 3X = Village. PP: x or x + 20, from the same ID
# 31,: square
# 32: sunny square
# 33: school yard
# 34: castle (green area)
# 41: square
# 42: school yard
# 43: green area

# 2024

y = 2024

addPath = string("Grabels_", y)
fileLoc = string(path, "/", addPath, "/data_ful_grabels_2024_final.xlsx")
PP = DataFrame(XLSX.readtable(fileLoc, "PP_count_2024"))
BG = DataFrame(XLSX.readtable(fileLoc, "BG_count_2024"))
BGdet = DataFrame(XLSX.readtable(fileLoc, "Dissection_2024"))


PP2024df = @chain PP begin
    @rename(dateObservation = DATE_COLLECTE, idTrap = ID_PIEGE, laidEggs = NB_eggs)
    @filter(laidEggs != "NA")
    #@mutate(laidEggs = convert(Int, laidEggs))
    @mutate(lengthObservation = dateObservation - DATE_POSE)
    @mutate(laidEggsperDay = laidEggs / (lengthObservation  / Day(1)) )
    @mutate(laidEggsWeekly =  7*laidEggsperDay)
    @select((idTrap, dateObservation, lengthObservation, laidEggs, laidEggsperDay, laidEggsWeekly))
end

BGdet2024df = @chain BG_det begin
    @group_by(ID_COLLECTE)
    @summarise(parous = sum(Parturite == "pare"),
    nulliparous = sum(Parturite == "nullipare"),
    gravids = sum(Parturite == "gravide"))
    @ungroup()
end



BG2024df = @chain @left_join(BG, BGdet2024df) begin
    @rename(dateObservation = DATE_COLLECTE, idTrap = ID_PIEGE,
    totAdults = NB_ALBO_TOT, totFemales = NB_ALBO_F, totGorged = NB_ALBO_F_G,
    totParous = parous, totNulliparous = nulliparous, totGravids = gravids)
    @select((idTrap, dateObservation, totAdults, totFemales, totGorged,
    totParous, totNulliparous, totGravids))
    @filter(totAdults != "NA")
end

# 2025

y = 2025

addPath = string("Grabels_", y)
fileLoc = string(path, "/", addPath, "/data_ful_grabels_090126.xlsx")
PP = DataFrame(XLSX.readtable(fileLoc, "PP_count_2025"))
BG = DataFrame(XLSX.readtable(fileLoc, "BG_count_2025"))
BGdet = DataFrame(XLSX.readtable(fileLoc, "Dissection_2025"))

PP2025df = @chain PP begin
    @rename(dateObservation = DATE_COLLECTE, idTrap = ID_PIEGE, laidEggs = NB_eggs)
    @filter(laidEggs != "NA")
    #@mutate(laidEggs = convert(Int, laidEggs))
    @mutate(lengthObservation = dateObservation - DATE_POSE)
    @mutate(laidEggsperDay = laidEggs / (lengthObservation  / Day(1)) )
    @mutate(laidEggsWeekly =  7*laidEggsperDay)
end

#further elab to manage series of the same BG

PP2025df = @chain PP2025df begin
    #@mutate(idn = parse(Int, idTrap[3:4]))
    #@mutate(samePP = case_when(idn > 50) => string("BG", idn-20),
    @mutate(sameIdTrap = 
        case_when(idTrap == "BG51" => string("BG31"),
        idTrap == "BG52" => string("BG32"),
        idTrap == "BG53" => string("BG33"),
        idTrap == "BG54" => string("BG34"),
        idTrap == "BG61" => string("BG41"),
        idTrap == "BG62" => string("BG42"),
        idTrap == "BG63" => string("BG43"),
        idTrap == "BG64" => string("BG44"),
        true => idTrap))
    @group_by(sameIdTrap, dateObservation)
    @summarise(laidEggs = mean(laidEggs),
    laidEggsperDay = mean(laidEggsperDay),
    laidEggsWeekly = mean(laidEggsWeekly),
    lengthObservation = rand(lengthObservation), #only possibility
    idTrap = sameIdTrap)
    @ungroup()
    @select((idTrap, dateObservation, lengthObservation, laidEggs, laidEggsperDay, laidEggsWeekly))
end

BGdet2025df = @chain BG_det begin
    @group_by(ID_COLLECTE)
    @summarise(parous = sum(Parturite == "pare"),
    nulliparous = sum(Parturite == "nullipare"),
    gravids = sum(Parturite == "gravide"))
    @ungroup()
end

BG2025df = @chain @left_join(BG, BGdet2025df) begin
    @rename(dateObservation = DATE_COLLECTE, idTrap = ID_PIEGE,
    totAdults = NB_ALBO_TOT, totFemales = NB_ALBO_F, totGorged = NB_ALBO_F_G,
    totParous = parous, totNulliparous = nulliparous, totGravids = gravids)
    @select((idTrap, dateObservation, totAdults, totFemales, totGorged,
    totParous, totNulliparous, totGravids))
    @filter(totAdults != "NA")
end

# rbind DataFrames

BGdf = [BG2024df; BG2025df]
PPdf = [PP2024df; PP2025df]

idTraps = unique(BGdf.idTrap)

for id in idTraps

    BGiDdf = @chain BGdf begin
        @filter(idTrap == !!id)
    end
    CSV.write(string("data/BG_Grabels_", id, "_2024_2026.csv"), BGiDdf)

    PPiDdf = @chain PPdf begin
        @filter(idTrap == !!id)
    end

    CSV.write(string("data/PP_Grabels_", id, "_2024_2026.csv"), PPiDdf)
end