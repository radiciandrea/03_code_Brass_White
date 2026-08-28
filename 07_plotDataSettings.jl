# Agent data save
Ed(m) = m isa immatureMosquito && m.stage == 0 ? sum(m.abundance) : 0
E(m) = m isa immatureMosquito && m.stage == 1 ? sum(m.abundance) : 0
Eq(m) = m isa immatureMosquito && m.stage == 2 ? sum(m.abundance) : 0
L(m) = m isa immatureMosquito && m.stage == 3 ? sum(m.abundance) : 0
P(m) = m isa immatureMosquito && m.stage == 4 ? sum(m.abundance) : 0
A(m) = m isa adultMosquito ? 1 : 0

adata = [(Ed, sum), (E, sum), (Eq, sum), (L, sum), (P, sum), (A, sum)]

# Model data save
O(model) = model.laidE + model.laidED
V(model) = model.V

#mdata = [O, V]

Q(model) = model.Q
hQ(model) = model.hQ
alpha(model) = model.alpha
deltaL(model) = model.deltaLdt/model.dt
muL(model) = model.muLdt/model.dt

mdata = [O, V, Q, hQ, alpha, deltaL, muL]