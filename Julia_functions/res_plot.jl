function result_plot()
    time = LinRange(0, tF, length(T))

    PyPlot.pygui(true)
    fig, axs = plt.subplots(4, 1, figsize=(6, 12))
    axs[1].plot(time, T, label="Temp", color="green")
    axs[1].set_title("Temperature Profile")
    axs[1].set_xlabel("Time (hours)")
    axs[1].set_ylabel("Temperature (°C)")
    axs[1].legend()
    
    # Heat source plot
    axs[2].plot(time, q)
    axs[2].set_title("Optimal Heating Schedule")
    axs[2].set_xlabel("Time (hours)")
    axs[2].set_ylabel("Watt [W]")
    
    axs[3].plot(hour_lst, price_NOK)
    axs[3].set_title("Energy price over time")
    axs[3].set_xlabel("Time (hours)")
    axs[3].set_ylabel("Price (NOK)")
    axs[3].legend()
    
    axs[4].plot(hour_lst, T_out)
    axs[4].set_title("Temperature over time")
    axs[4].set_xlabel("Time (hours)")
    axs[4].set_ylabel("Temperature (°C)")
    axs[4].legend()
    
    plt.show()
    

end