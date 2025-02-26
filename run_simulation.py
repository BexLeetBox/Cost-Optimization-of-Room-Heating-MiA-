import os
from OMPython import OMCSessionZMQ
import matplotlib.pyplot as plt
from scipy.io import loadmat

# Start OpenModelica session
omc = OMCSessionZMQ()

# Load the Buildings Library
omc.sendExpression("loadModel(Buildings)")

# Define Simulation Directory
simulation_dir = os.path.join(os.getcwd(), "simulation_outputs")
os.makedirs(simulation_dir, exist_ok=True)
os.chdir(simulation_dir)  # Run the simulation in a separate directory

# Load the Modelica file
modelica_file = os.path.join(os.getcwd(), "HeatConduction.mo")
omc.sendExpression(f'loadFile("{modelica_file}")')

# Check if the model is loaded
if "HeatConductionSimulation" not in omc.sendExpression("getClassNames()"):
    print("Error: Model not loaded properly!")
    exit()

# Run the Simulation
result = omc.sendExpression(f"simulate(HeatConductionSimulation, stopTime=3600)")
result_file = result.get("resultFile", "No file generated")

# Get error messages if the simulation fails
error_message = omc.sendExpression("getErrorString()")
if error_message:
    print("\n===== OpenModelica Error Log =====")
    print(error_message)

# Load and Plot Results
if result_file != "No file generated":
    data = loadmat(result_file)
    
    time = data["time"].flatten()
    temperature = data["wall.T"].flatten()  # Update this based on `data.keys()`

    plt.figure(figsize=(10, 5))
    plt.plot(time, temperature, label="Wall Temperature (K)", color="red")
    plt.xlabel("Time (s)")
    plt.ylabel("Temperature (K)")
    plt.title("Temperature Evolution in the Wall")
    plt.legend()
    plt.grid(True)
    plt.show()
