function E(T,Q)
	E=0.0
	for (t,QQ) in Q
		# E+=Δt*price(t)^2*∑(∫(QQ*QQ)*dΩ)
		E+=Δt*price(t)*∑(∫(QQ)*dΩ)

	end
	tmp=last(T)[2]-Tfin
	E+=0.5*γ*∑(∫(tmp*tmp)*dΩ)
	return E
end


∇e(Q::Vector{Tuple{Float64, SingleFieldFEFunction{GenericCellField{ReferenceDomain}}}},
T, W) = [(T[k][1],price(T[k][1])-W[k][2]) for k=1:length(Q)]