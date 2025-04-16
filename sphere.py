import paraview.web.venv  # noqa: F401
from paraview.simple import *
from trame.app import get_server
from trame.ui.vuetify import SinglePageLayout
from trame.widgets import paraview as pv, vuetify
import time
from threading import Thread


# Initialize the Trame server
server = get_server(client_type="vue2")
state, ctrl = server.state, server.controller
state.playing = False
state.time = 0


# Load PVD data
pvd_reader = OpenDataFile(r"C:\Users\47973\OneDrive - NTNU\NTNU\4 år\Applied Mathematics\Cost-Optimization-of-Room-Heating-MiA-\results.pvd")
pvd_reader.CellArrays = ['cell']
pvd_reader.PointArrays = ['u']
UpdatePipeline()

# Setup render view
render_view = GetActiveViewOrCreate('RenderView')
render_view.InteractionMode = "2D"  # Lock rotation
display = Show(pvd_reader, render_view)
ColorBy(display, ("POINTS", "u"))

display.RescaleTransferFunctionToDataRange(False, True)
display.SetScalarBarVisibility(render_view, True)
render_view.ResetCamera()

ctrl.view_update = lambda: server._push_state()


def toggle_play():
    if state.playing:
        state.playing = False
    else:
        state.playing = True
        playback_loop()


def playback_loop():
    def loop():
        while state.time < len(pvd_reader.TimestepValues) - 1 and state.playing:
            time.sleep(0.1)
            state.time += 1
            render_view.ViewTime = pvd_reader.TimestepValues[state.time]
            print("looping")
            update_view()
        state.playing = False
    Thread(target=loop, daemon=True).start()

def reset_time():
    state.time = 0
    render_view.ViewTime = pvd_reader.TimestepValues[0]
    update_view()

def update_view():
    state.dirty("time")


# Setup Trame layout
with SinglePageLayout(server) as layout:
    layout.title.set_text("Room Heating Simulation - ParaView Web")

    with layout.content:
        # Sidebar
        with vuetify.VNavigationDrawer(app=True, permanent=True, width="180"):
            vuetify.VListItemTitle("Controls")
            vuetify.VBtn(text=True, click=ctrl.reset_camera, children=["Reset Camera"])
            vuetify.VBtn(text=True, click=ctrl.reset_view, children=["Zoom to Data"])
            vuetify.VBtn(text=True, click=reset_time, children=["Reset Time"])
            vuetify.VBtn(text=True, click=toggle_play, children=["Play"])


        # Main view
        pv.VtkRemoteView(render_view, ref="view")

    with layout.toolbar:

        vuetify.VSpacer()
        """
        vuetify.VSlider(
            v_model=("time", 0),
            min=0,
            max=len(pvd_reader.TimestepValues) - 1,
            step=1,
            dense=True,
            hide_details=True,
            style="max-width: 300px",
            change=ctrl.view_update,
        )
        vuetify.VBtn(icon=True, click=ctrl.previous_timestep).add_child("mdi-skip-previous")
        vuetify.VBtn(icon=True, click=toggle_play).add_child("mdi-play")
        vuetify.VBtn(icon=True, click=ctrl.next_timestep).add_child("mdi-skip-next")
        vuetify.VBtn(icon=True, click=lambda: setattr(state, "time", 0)).add_child("mdi-refresh")
"""
# Start the app
server.start()
