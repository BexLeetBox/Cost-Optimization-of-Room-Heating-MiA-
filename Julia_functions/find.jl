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