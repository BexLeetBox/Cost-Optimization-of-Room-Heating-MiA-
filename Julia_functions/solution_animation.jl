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