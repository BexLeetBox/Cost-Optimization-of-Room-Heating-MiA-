function find(y,s)
	tsave,ysave=t0,nothing
	for (t,yy) in y
		ysave=yy
		break
	end
	for (t,yy) in y
		# if t≈t0
		# 	ysave=yy
		# 	tsave=t0
		# end
		if t≈s
			return yy
		elseif t ≥ s
			return interpolate_everywhere(((s-tsave)*ysave+(t-s)*yy)/Δt, Uspace(s))
		end
		tsave,ysave = t,yy
	end
end
# function find(y, s)
# 	# y: vector of (t, value)
# 	# s: time to evaluate at
# 	# Δt: time step
# 	# Uspace: function mapping t -> finite element space

# 	prev_t, prev_val = nothing, nothing

# 	for (t, val) in y
# 		if isapprox(t, s; atol=1e-10)
# 			return val
# 		elseif t > s && prev_t !== nothing
# 			# linear interpolation
# 			interp_val = ((s - prev_t)*val + (t - s)*prev_val)/Δt
# 			return interpolate_everywhere(interp_val, Uspace(s))
# 		end
# 		prev_t, prev_val = t, val
# 	end

# 	# If s is beyond last time, return final value
# 	return last(y)[2]
# end
# function find(y, s)
# 	# y: vector of (t, value)
# 	# s: time to evaluate at
# 	# Δt: time step
# 	# Uspace: function mapping t -> finite element space

# 	prev_t, prev_val = nothing, nothing

# 	for (t, val) in y
# 		if isapprox(t, s; atol=1e-10)
# 			return val
# 		elseif t > s && prev_t !== nothing
# 			# linear interpolation
# 			interp_val = ((s - prev_t)*val + (t - s)*prev_val)/Δt
# 			return interpolate_everywhere(interp_val, Uspace(s))
# 		end
# 		prev_t, prev_val = t, val
# 	end

# 	# If s is beyond last time, return final value
# 	return last(y)[2]
# end
