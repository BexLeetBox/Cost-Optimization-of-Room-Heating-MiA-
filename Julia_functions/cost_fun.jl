function E(T,Q)
	E=0.0
	for (t,QQ) in Q
		E+=Δt*price(t)^2*∑(∫(QQ*QQ)*dΩ)
	end
	tmp=last(T)[2]-Tfin
	E+=0.5*γ*∑(∫(tmp*tmp)*dΩ)
	
	return E
end


∇e(Q::Vector{Tuple{Float64, SingleFieldFEFunction{GenericCellField{ReferenceDomain}}}},
T, W) = [(Q[k][1],2*price(T[k][1])^2*Q[k][2]-W[k][2]) for k=1:length(Q)]                                                # gradient of reduced cost

function ∇e(Qt::Function,
T::Vector{Tuple{Float64, SingleFieldFEFunction{GenericCellField{ReferenceDomain}}}},
W::Vector{Tuple{Float64, SingleFieldFEFunction{GenericCellField{ReferenceDomain}}}})
	return collect((T[k][1],interpolate_everywhere(2*price(T[k][1])^2*Qt(T[k][1])-ρ*W[k][2]*c,Uspace(T[k][1]))) for k=1:length(W))
end