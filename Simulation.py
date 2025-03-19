import os
from OMPython import OMCSessionZMQ

# Start OpenModelica session
omc = OMCSessionZMQ()

# Load the Buildings library
load_status = omc.sendExpression("loadModel(Buildings)")
if not load_status:
    print("Error: Failed to load Buildings library.")
    exit()

# Define the simulation model
valid_model = "Buildings.Examples.SimpleHouse"

# Set the simulation output folder inside the project
simulation_dir = os.path.join(os.getcwd(), "simulation_outputs")
os.makedirs(simulation_dir, exist_ok=True)  # Ensure folder exists

# Change to the simulation directory
os.chdir(simulation_dir)

# Run the simulation
result = omc.sendExpression(f"simulate({valid_model}, stopTime=86400)")

# Get error message if simulation fails
error_message = omc.sendExpression("getErrorString()")
if error_message:
    print("\n===== OpenModelica Error Log =====")
    print(error_message)

# ✅ Check if result is None before proceeding
if result is None:
    print("Error: Simulation failed. No result returned from OpenModelica.")
    exit()

print("Simulation complete. Files stored in:", simulation_dir)

# Extract and display key results
simulation_status = {
    "Result File": result.get("resultFile", "No file generated"),
    "Simulation Status": "Success" if "LOG_SUCCESS" in result.get("messages", "") else "Failed",
    "Warnings": [msg for msg in result.get("messages", "").split("\n") if "warning" in msg.lower()],
    "Total Simulation Time": result.get("timeTotal", "Unknown"),
}

# Print summary (clean output)
print("\n===== Simulation Summary =====")
for key, value in simulation_status.items():
    if isinstance(value, list) and value:
        print(f"{key}:")
        for warning in value:
            print(f"  - {warning.strip()}")
    else:
        print(f"{key}: {value}")
