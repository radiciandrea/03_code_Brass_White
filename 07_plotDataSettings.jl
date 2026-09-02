# Agent data save
Ed(m) = m isa immatureMosquito && m.stage == 0 ? sum(m.abundance) : 0
E(m) = m isa immatureMosquito && m.stage == 1 ? sum(m.abundance) : 0
Eq(m) = m isa immatureMosquito && m.stage == 2 ? sum(m.abundance) : 0
L(m) = m isa immatureMosquito && m.stage == 3 ? sum(m.abundance) : 0
P(m) = m isa immatureMosquito && m.stage == 4 ? sum(m.abundance) : 0
A(m) = m isa adultMosquito ? 1 : 0
#VR(m) = m isa breedingSite && m.type == 1 ? m.V : 0
#VH(m) = m isa breedingSite && m.type == 2 ? m.V : 0

adata = [(Ed, sum), (E, sum), (Eq, sum), (L, sum), (P, sum), (A, sum)]

# Model data save
O(model) = model.laidEf + model.laidEDf
deltaE(model) = model.deltaEdt/model.dt
muE(model) = model.muEdt/model.dt
VR(model) = model[3].V
VH(model) = model[4].V

mdata = [O, deltaE, muE, VR, VH]