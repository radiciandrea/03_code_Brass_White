
# Agent data save
Ed(m) = m isa immatureMosquito && m.stage == 0 ? sum(m.abundance) : 0
E(m) = m isa immatureMosquito && m.stage == 1 ? sum(m.abundance) : 0
J(m) = m isa immatureMosquito && m.stage == 2 ? sum(m.abundance) : 0
I(m) = m isa adultMosquito && m.stage == 0 ? 1 : 0
A(m) = m isa adultMosquito && m.stage == 1 ? 1 : 0

adata = [(Ed, sum), (E, sum), (J, sum), (I, sum), (A, sum)]

# Model data save
O(model) = model.laidE + model.laidED

mdata = [O]
