function s_min(Q,T,W,gradient;solveSE, solveAE, spaces, w=nothing, dΩ, dΓ=nothing, s_ini=nothing, Δt=0.05, t0=0.0, tF)
	Trialspace, Testspace, FEspace = spaces
	gradfun(t)=find(gradient,t)
	Sv,_ = solveSE(gradfun,Trialspace,Testspace;w=w,dΩ=dΩ,dΓ=dΓ)
	L2NormSquaredOfv = (tF-t0)*∑(Δt*∑(∫(uu⋅uu)*dΩ) for (t,uu) in gradient)                                 # ||v||^2
	L2NormSquaredSv = (tF-t0)*∑(Δt*∑(∫(uu⋅uu)*dΩ) for (t,uu) in Sv)
	L2NormSquaredpv = (tF-t0)*∑(Δt*∑(∫(uu⋅uu*price*price)*dΩ) for (t,uu) in gradient)
	return -L2NormSquaredOfv/(2*(L2NormSquaredpv+γ/2*L2NormSquaredSv)) # -s_min because originally v=-∇e but calculating this costs much more time
end



function GradientDescent(;solveSE, solveAE, spaces, dΩ, dΓ=nothing, Q, J, ∇f, iter_max=1000, tol=1e-3, P=x->x, u0=nothing, w=nothing, s_min=nothing, sminargs=nothing, armijoparas=(ρ=1/2, α_0=1, α_min=1/2^5, σ=1e-4), Δt=0.01, t0=0.0, tF, saveall::Bool=false, Tout=nothing, constants=nothing, Tfin, q_pos)

	Trialspace, Testspace, Qspace = spaces                                  # Extract spaces
	
	ls = LUSolver()
	θ = 0.5
	solver = ThetaMethod(ls, Δt, θ)
	
	if typeof(Q) == Vector{Tuple{Float64, SingleFieldFEFunction{GenericCellField{ReferenceDomain}}}}
		q = Q
	else
		q = [(t,interpolate_everywhere(Q(t),Qspace(t))) for t=t0:Δt:tF]
	end

	# q = [(t,interpolate_everywhere(Q(t),Qspace(t))) for t=t0:Δt:tF]    # Initialize u with some random values and apply projection
	qfun(t)=find(q,t)

	T, cacheSE, A_SE = SEsolver(solver, Qt, Trialspace, Testspace; dΩ, dΓ, Tout, constants)  # initial SE solve
	
	Tfun(t)=find(T,t)
	println("T computed")

	W, cacheAE, A_AE = solveAE(solver, Tfun,q,Trialspace,Testspace,dΩ=dΩ,dΓ=dΓ, Tfin=Tfin,tF=tF, constants=constants)      # initial AE solve
	#p = FEFunction(Testspace, p_dof)
	println("W computed")
	
	cost = J(T, q)
	fgrad =  ∇f(q, T, W)														# Compute initial gradient
	L2fgrad_save = L2norm(fgrad)                                       # Compute norm of initial gradient

	if saveall
		qs=[q]                     # save the solutions - only if really necessary
		Ts=[T]
		Ws=[W]
		costs=[cost]
	else
		qs,Ts,Ws=[],[],[]
	end


	for k=1:iter_max
		println("entered for loop, E=$cost, k = $k")
		s_min = nothing
		if s_min != nothing
			q_new = T_new = cost_new = qfunnew = nothing

			# s = s_min(q,y,p,fgrad;solveSE=solveSE, solveAE=solveAE, spaces=spaces, w=w, dΩ=dΩ, dΓ=dΓ, Δt=Δt, t0=t0, tF=tF)
			# println("step $k, s_min = $s")
	
			q_new = [(t,interpolate_everywhere((qfun(t) - 0.00001*grad)*q_pos, Qspace(t))) for (t,grad) in fgrad] #|> Proj #interpolate_everywhere(q - s*fgrad,Qspace) |> P			# in most cases interpolate instead of interpolate_everywhere works as well
			# q_new = [(t,interpolate_everywhere((qfun(t) - 0.0001*grad), Qspace(t))) for (t,grad) in fgrad] #interpolate_everywhere(q - s*fgrad,Qspace) |> P			# in most cases interpolate instead of interpolate_everywhere works as well
	
			qfunnew=t->find(q_new,t)
			T_new, cacheSE = solveSE(solver, qfunnew, Trialspace, Testspace; dΩ, dΓ, Tout, constants)
			#y_new = FEFunction(Trialspace, y_dof)	
			cost_new = J(T_new,q_new)	
		else
			ρ, α_0, α_min, σ = armijoparas
			cost_new = cost
			L2fgrad = L2norm(fgrad)
			α = α_0
			while α > α_min
				q_new = [(t,interpolate_everywhere((qfun(t) - α*grad)*q_pos, Qspace(t))) for (t,grad) in fgrad] |> P    # Compute tentative new control function defined by current line search parameter
				qfunnew=t->find(q_new,t)

				T_new, cacheSE = solveSE(solver, qfunnew, Trialspace, Testspace; dΩ, dΓ, Tout, constants)
				
				interm = σ*α*L2fgrad^2

				#y_new = FEFunction(Trialspace, y_dof)
				println("α = $α, new_cost = $cost_new, L2fgrad = $L2fgrad, interm = $interm")
				cost_new = J(T_new, q_new)                                  # Compare decrease in functional and accept if sufficient
				if cost_new < cost - σ*α*L2fgrad^2
					break
				else
					α *= ρ
				end
			end
			if α <= α_min
				println("Armijo rule failed, α = $α")
				break
			end
		end
		# println("α = $α")

		q = q_new
		T = T_new
		qfun = qfunnew
		cost = cost_new
		
		if saveall
			push!(qs,q)
			push!(Ts,T)
			push!(costs,cost)
			push!(Ws,W)
		end
		Tfun=t->find(T,t)
		W, cacheAE = solveAE(solver, Tfun,q,Trialspace,Testspace,dΩ=dΩ,dΓ=dΓ, Tfin=Tfin,tF=tF, constants=constants)
		
		fgrad = ∇f(q, T, W)
		L2fgrad = L2norm(fgrad)
		

		if L2fgrad < tol*L2fgrad_save                           # loop break condition - better ideas are appreciated
			break
		end
	
	end
	return saveall ? (Ts,qs,Ws,costs) : (T,q,W,cost)                    	# give back either all saved variables or only end result
end