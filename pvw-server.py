# pvw-server.py
import os
from paraview.web import pv_web_visualizer
from wslink import server

# Location of the simulation results
DATA_DIRECTORY = os.path.abspath(".")

class _ServerProtocol(pv_web_visualizer.VisualizerServer):
    def initialize(self):
        super().initialize()
        self.getApplication().SetDirectory(DATA_DIRECTORY)

if __name__ == "__main__":
    server.start_webserver(
        protocol=_ServerProtocol,
        disableLogging=True,
        port=12345,
        content={"src": "."}  # serve static frontend from current directory
    )
