function result_plot()
    PyPlot.pygui(true)

    fig, axs = plt.subplots(3, 1, figsize=(6, 12))
    
    # Price plot
    axs[1].plot(sin.(0:0.1:2π), label="sin(x)", color="blue")
    axs[1].set_title("Energy Price")
    axs[1].set_xlabel("Time (hours)")
    axs[1].set_ylabel("Price (kr/kWh)")
    axs[1].legend()
    
    # Heat source plot
    axs[2].hist(randn(100), bins=10, color="purple", alpha=0.7)
    axs[2].set_title("Optimal Heating Schedule")
    axs[2].set_xlabel("Time (hours)")
    axs[2].set_ylabel("Watt [W]")
    
    # Temperature plot
    axs[3].plot(exp.(0:0.1:2), label="exp(x)", color="green")
    axs[3].set_title("Temperature Profile")
    axs[3].set_xlabel("Time (hours)")
    axs[3].set_ylabel("Temperature (°C)")
    axs[3].legend()
    
    # Juster layout for å unngå overlapp
    plt.tight_layout()
    plt.show()
    

end