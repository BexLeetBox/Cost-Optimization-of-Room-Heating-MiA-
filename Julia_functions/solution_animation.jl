function solution_animation(solutions, framerate)
    # Observable for time
    time = Observable(1)  # Start at time step 1

    # Initial plot
    fig, ax, plt = plot(Ω, solutions[1], colormap=:plasma)

    # Colorbar for visualization
    Colorbar(fig[1, 2], plt)

    # Make the solution observable
    sol_obs = @lift(solutions[$time])  

    # Update the plot dynamically
    plt = plot!(Ω, sol_obs, colormap=:plasma)  

    # Create the animation
    timestamps = 1:length(solutions)

    record(fig, "animation.mp4", timestamps; framerate=framerate) do t
        time[] = t  # Update time observable
    end
end

function draw(ysol)
	fig, _ , plt = CairoMakie.plot(Ω, ysol, colormap=:plasma)               # plot of last state (numerical solution)
	CairoMakie.wireframe!(Ω, color=:black, linewidth=1)                        # add triangulation
	CairoMakie.Colorbar(fig[1,2], plt)                                         # add color bar
	display(fig)															  # display the plot
end



function savePVDall(ys, qs, ps)
    for k = 1:length(ys)
        if !isdir("tmpse$k")
            mkdir("tmpse$k")
        end
        createpvd("results_se$k") do pvd
            for (tn, uhn) in ys[k]
                pvd[tn] = createvtk(Ω, "tmpse$k/results_se{$k}_$tn" * ".vtu", cellfields=["u" => uhn])
            end
        end
    end
    for k = 1:length(ps)
        if !isdir("tmpadj$k")
            mkdir("tmpadj$k")
        end
        createpvd("results_adj$k") do pvd
            for (tn, uhn) in ps[k]
                pvd[tn] = createvtk(Ω, "tmpadj$k/results_adj{$k}_$tn" * ".vtu", cellfields=["u" => uhn])
            end
        end
    end
    for k = 1:length(qs)
        if !isdir("tmpcont$k")
            mkdir("tmpcont$k")
        end
        createpvd("results_cont$k") do pvd
            for (tn, uhn) in qs[k]
                pvd[tn] = createvtk(Ω, "tmpcont$k/results_cont{$k}_$tn" * ".vtu", cellfields=["u" => uhn])
            end
        end
    end
end