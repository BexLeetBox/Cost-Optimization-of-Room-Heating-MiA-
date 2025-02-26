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

# Set a temporary working directory
temp_dir = "C:/Users/47973/AppData/Local/Temp/ModelicaSim"
os.makedirs(temp_dir, exist_ok=True)  # Ensure directory exists

# Change to the temporary working directory
os.chdir(temp_dir)

# Run the simulation with the correct syntax
result = omc.sendExpression(f"simulate({valid_model}, stopTime=86400)")

# Get the error message if simulation fails
error_message = omc.sendExpression("getErrorString()")
if error_message:
    print("\n===== OpenModelica Error Log =====")
    print(error_message)

# ✅ Check if result is None before proceeding
if result is None:
    print("Error: Simulation failed. No result returned from OpenModelica.")
    exit()

print("Simulation complete. Files stored in:", temp_dir)

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
