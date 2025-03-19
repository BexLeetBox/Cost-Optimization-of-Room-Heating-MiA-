function s_min(Q,T,W,gradient;solveSE, solveAE, spaces, w=nothing, dΩ, dΓ=nothing, s_ini=nothing, Δt=0.05, t0=0.0, tF)
	Trialspace, Testspace, FEspace = spaces
	gradfun(t)=find(gradient,t)
	Sv,_ = solveSE(gradfun,Trialspace,Testspace;w=w,dΩ=dΩ,dΓ=dΓ)
	L2NormSquaredOfv = (tF-t0)*∑(Δt*∑(∫(uu⋅uu)*dΩ) for (t,uu) in gradient)                                 # ||v||^2
	L2NormSquaredSv = (tF-t0)*∑(Δt*∑(∫(uu⋅uu)*dΩ) for (t,uu) in Sv)
	L2NormSquaredpv = (tF-t0)*∑(Δt*∑(∫(uu⋅uu*price*price)*dΩ) for (t,uu) in gradient)
	return -L2NormSquaredOfv/(2*(L2NormSquaredpv+γ/2*L2NormSquaredSv)) # -s_min because originally v=-∇e but calculating this costs much more time
end

function GradientDescent(;solveSE, solveAE, spaces, dΩ, dΓ=nothing, Q, J, ∇f, iter_max=1000, tol=1e-3, P=x->x, u0=nothing, w=nothing, s_min=nothing, sminargs=nothing, Δt=0.05, t0=0.0, tF, saveall::Bool=false)
	Trialspace, Testspace, Qspace = spaces
	
	q = [(t,interpolate_everywhere(Q(t),Qspace(t))) for t=t0:Δt:tF]    # Initialize u with some random values and apply projection
	qfun(t)=find(q,t)
	println("q computed")

	y, cacheSE, A_SE = solveSE(Q,Trialspace,Testspace,w=w,dΩ=dΩ,dΓ=dΓ)  # initial SE solve
	#y = FEFunction(Trialspace, y_dof)
	yfun(t)=find(y,t)
	println("y computed")
	
	p, cacheAE, A_AE = solveAE(yfun,q,Trialspace,Testspace,dΩ=dΩ,dΓ=dΓ)      # initial AE solve
	#p = FEFunction(Testspace, p_dof)
	println("p computed")
	
	cost = J(y, q)
	fgrad =  ∇f(q, p, y)														# Compute initial gradient
	L2fgrad_save = L2norm(fgrad)                                       # Compute norm of initial gradient

	if saveall
		qs=[q]                     # save the solutions - only if really necessary
		ys=[y]
		ps=[p]
		costs=[cost]
	else
		qs,ys,ps=[],[],[]
	end
	for k=1:iter_max
		println("entered for loop, E=$cost")
		q_new = y_new = cost_new = qfunnew = nothing
		s = s_min(q,y,p,fgrad;solveSE=solveSE, solveAE=solveAE, spaces=spaces, w=w, dΩ=dΩ, dΓ=dΓ, Δt=Δt, t0=t0, tF=tF)
		println("s_min = $s")
		q_new = [(t,interpolate_everywhere(qfun(t) - s*grad, Qspace(t))) for (t,grad) in fgrad] #|> Proj interpolate_everywhere(q - s*fgrad,Qspace) |> P			# in most cases interpolate instead of interpolate_everywhere works as well
		qfunnew=t->find(q_new,t)
		y_new, cacheSE = solveSE(qfunnew,Trialspace,Testspace;w=w,dΩ=dΩ,dΓ=dΓ)
		#y_new = FEFunction(Trialspace, y_dof)
		cost_new = J(y_new,q_new)
		
		q = q_new
		y = y_new
		qfun = qfunnew
		cost = cost_new
		
		if k % 10 == 0
			println("iteration: $k,   cost = $cost")
		end

		if saveall
			push!(qs,q)
			push!(ys,y)
			push!(costs,cost)
		end

		yfun=t->find(y,t)
		p, cacheAE = solveAE(yfun,q,Trialspace,Testspace;dΩ=dΩ,dΓ=dΓ)
		#p = FEFunction(Testspace, p_dof)

		fgrad = ∇f(q, p, y)
		L2fgrad = L2norm(fgrad)
		push!(ps,p)

		if L2fgrad < tol*L2fgrad_save                           # loop break condition - better ideas are appreciated
			break
		end
	end
	return saveall ? (ys,qs,ps,costs) : (y,q,p,cost)                    	# give back either all saved variables or only end result
end