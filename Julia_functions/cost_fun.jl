function E(T,Q)
	E=0.0
	for (t,QQ) in Q
		E+=Δt*price(t)^2*γ*∑(∫(QQ*QQ)*dΩ)
	end
	tmp=last(T)[2]-Tfin
	E+=∑(∫(tmp*tmp)*dΩ)
	# for (TT,t) in T
	# 	tmp=TT-20.0
	# 	E+=Δt*∑(∫(tmp*tmp)*dΩ)
	# end
	return E/2.0
end


∇e(Q::Vector{Tuple{Float64, SingleFieldFEFunction{GenericCellField{ReferenceDomain}}}},
T::Vector{Tuple{Float64, SingleFieldFEFunction{GenericCellField{ReferenceDomain}}}},
W::Vector{Tuple{Float64, SingleFieldFEFunction{GenericCellField{ReferenceDomain}}}}) = [(Q[k][1],2*price(T[k][1])^2*Q[k][2]-ρ*W[k][2]*c) for k=1:length(Q)]                                                # gradient of reduced cost
function ∇e(Qt::Function,
T::Vector{Tuple{Float64, SingleFieldFEFunction{GenericCellField{ReferenceDomain}}}},
W::Vector{Tuple{Float64, SingleFieldFEFunction{GenericCellField{ReferenceDomain}}}})
	println(T)
	println(W)
	return collect((T[k][1],interpolate_everywhere(2*price(T[k][1])^2*Qt(T[k][1])-ρ*W[k][2]*c,Uspace(T[k][1]))) for k=1:length(W))
end