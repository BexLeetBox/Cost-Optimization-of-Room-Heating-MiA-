function get_temperature_int(Ts, width, height)
	tmp = []
	for temp in Ts
	push!(tmp, ∑(∫(temp[2])*dΩ))
	end
	return tmp / (width * height)
end


function get_control_int(qs)
    q = []
	for u in qs
	push!(q, ∑(∫(u[2])*dΩ))
	end
	return q
end

