function s_min(y,q,w,p;sminargs)
	cache,A=sminargs
	v=interpolate(-y*p+γ*q, Uspace)                                      # v=p+γ*u, since all uses of v are in norms we can ignore the minus
	Sv,_ = SEsolver(v,Trialspace,Testspace;dΩ=dΩ,cache=cache,A=A)
	Sv = FEFunction(Trialspace,Sv)
	L2NormSquaredOfv = ∑(∫(v*v)*dΩ)                                   # ||v||^2
	return L2NormSquaredOfv/(∑(∫(Sv*Sv)*dΩ)+γ*L2NormSquaredOfv)
end








function GradientDescent(;solveSE, solveAE, spaces, dΩ, dΓ=nothing, J, ∇f, iter_max=1000, tol=1e-3, P=x->x, u0=nothing, w=nothing, s_min=nothing, sminargs=nothing, armijoparas=(ρ=1/2, α_0=1, α_min=1/2^5, σ=1e-4), saveall::Bool=false)
	#=
	Solves any CP with possibly box bounds
	Input: (all are named arguments - oder does not matter, but they have to be called by name)
	  solveSE   - a method to solve the SE, Input: u (rhs), Trialspace, Testspace. optional: dΩ, dΓ, cache from earlier execution, y_dof pre-solution in vector-form to write on. Output: solution, cache
	  solve AE  - a method to solve the AE, Input: y (rhs), Trialspace, Testspace. optional: dΩ, dΓ, cache from earlier execution, p_dof pre-solution in vector-form to write on. Output: solution, cache
	  spaces    - tuple of (trial space, test space, FE space)
	  dΩ        - measure on Ω
	  dΓ        - measure on ∂Ω=Γ (optional)
	  J         - functional to minimise (only needed for early breaking out of loop)
	  ∇f        - functional to compute gradient of reduced cost f
	  iter_max  - number of maximum iterations (default 2000)
	  tol       - tolerance for early break out of loop (default 10^(-3))
	  P         - Projection onto box. P is assumed to have the form u↦P(u) and should be able to handle an FEFunction as input (default without) and give such as output
	  u0        - start function for u (optional, default without)
	  w         - boundary term (default without)
	  s_min     - function to compute exact step size (default without - then Armijo rule will be used). Input is supposed to be y,u,w,p (from algorithm) and sminargs will be unloaded
	  sminargs  - additional arguments for s_min that can be given
	  armijoparas   - parameters for Armijo rule. defaults are given and can individually be changed (named arguments)
	=#
	Trialspace, Testspace, Qspace = spaces                                  # Extract spaces

	q = FEFunction(Qspace, rand(Float64, num_free_dofs(Qspace)) |> P)       # Initialize u with some random values and apply projection

	y, cacheSE, A_SE = solveSE(q,Trialspace,Testspace,w=w,dΩ=dΩ,dΓ=dΓ)  # initial SE solve
	#y = FEFunction(Trialspace, y_dof)

	p, cacheAE, A_AE = solveAE(y,q,Trialspace,Testspace,dΩ=dΩ,dΓ=dΓ)      # initial AE solve
	#p = FEFunction(Testspace, p_dof)
	
	cost = J(y, q)
	fgrad =  ∇f(q, p, y)														# Compute initial gradient
	L2fgrad0 = √(∑(∫(fgrad⋅fgrad)*dΩ))                                       # Compute norm of initial gradient

	if saveall
		qs=[q]                     # save the solutions - only if really necessary
		ys=[y]
		ps=[p]
		costs=[cost]
	else
		qs,ys,ps=[],[],[]
	end
	for k=1:iter_max
		if √(∑(∫(fgrad⋅fgrad)*dΩ)) < tol*L2fgrad0                           # loop break condition - better ideas are appreciated
			break
		end
		q_new = y_new = cost_new = nothing
		if s_min!=nothing                                                   # if method for exact step size is defined use that
			s = s_min(y,q,w,p,sminargs=(cacheSE,A_SE,sminargs))
			q_new = interpolate_everywhere(q - s*fgrad,Qspace) |> P			# in most cases interpolate instead of interpolate_everywhere works as well
			y_dof, cacheSE = solveSE(q_new,Trialspace,Testspace;w=w,dΩ=dΩ,dΓ=dΓ,cache=cacheSE,A=A_SE,y_dof=y_dof)
			y_new = FEFunction(Trialspace, y_dof)
			cost_new = J(y,q)
		else                                                                # else use Armijo rule - if projection is used, you should consider smaller step size than default
			ρ, α_0, α_min, σ = armijoparas
			cost_new = cost
			α = α_0
			while α > α_min
				q_new = interpolate_everywhere(q - α*fgrad, Qspace) |> P    # Compute tentative new control function defined by current line search parameter

				y_new, cacheSE = solveSE(q_new,Trialspace,Testspace;w=w,dΩ=dΩ,dΓ=dΓ,cache=cacheSE,A=A_SE,y_dof=y_dof)
				#y_new = FEFunction(Trialspace, y_dof)

				cost_new = J(y_new, q_new)                                  # Compare decrease in functional and accept if sufficient
				if cost_new < cost - σ*α*∑(∫(fgrad⋅fgrad)*dΩ)
					break
				else
					α *= ρ
				end
			end
		end# here you could implement other methods
		q = q_new
		y = y_new
		cost = cost_new
		
		if saveall
			push!(qs,FEFunction(Qspace, get_free_dof_values(q)))
			push!(ys,y)
			push!(costs,cost)
		end
		p, cacheAE = solveAE(y,q,Trialspace,Testspace;dΩ=dΩ,dΓ=dΓ,cache=cacheAE,A=A_SE,p_dof=p_dof)
		#p = FEFunction(Testspace, p_dof)

		fgrad = ∇f(q, p, y)
		push!(ps,p)
	end
	return saveall ? (ys,qs,ps,costs) : (y,q,p,cost)                    	# give back either all saved variables or only end result
end