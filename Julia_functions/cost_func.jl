function E(T,P,γ)
	E=0.0
	for (TT,t) in T
		tmp=TT-20.0
		E+=Δt*∑(∫(tmp*tmp)*dΩ)
	end
	for (PP,t) in P
		E+=Δt*γ*∑(∫(PP*PP)*dΩ)
	end
	return E/2.0
end