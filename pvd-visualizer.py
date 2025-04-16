import paraview.web.venv  # noqa: F401
from paraview.simple import *
from trame.app import get_server
from trame.ui.vuetify import SinglePageLayout
from trame.widgets import paraview as pv, vuetify
import asyncio
from paraview.simple import servermanager

# -----------------------------------------------------------------------------
# Trame server setup
# -----------------------------------------------------------------------------
server = get_server(client_type="vue2")
state, ctrl = server.state, server.controller
animation_task = None

# Initialize custom states if desired
state.playing = False
state.time = 0

# -----------------------------------------------------------------------------
# Load data and set up visualization
# -----------------------------------------------------------------------------
pvd_reader = OpenDataFile(r"results.pvd")
pvd_reader.CellArrays = ["cell"]
pvd_reader.PointArrays = ["u"]
SetActiveSource(pvd_reader)
UpdatePipeline()

# Create/attach to a Render View
render_view = GetActiveViewOrCreate("RenderView")
render_view.InteractionMode = "2D"  # lock rotation for 2D
display = Show(pvd_reader, render_view)

# Color by 'u' (point data)
ColorBy(display, ("POINTS", "u"))

# Rescale color map to the min/max of 'u' across ALL timesteps
display.RescaleTransferFunctionToDataRange(False, True)

# Make sure we set an initial time and reset camera
if pvd_reader.TimestepValues:
    render_view.ViewTime = pvd_reader.TimestepValues[state.time]
render_view.ResetCamera()
state.dirty("time")

# Show the scalar bar for 'u'
display.SetScalarBarVisibility(render_view, True)

# Helper to mark the time state as dirty, so the UI can pick up changes
def update_view():
    state.dirty("time")


# -----------------------------------------------------------------------------
# Animation logic with an async loop
# -----------------------------------------------------------------------------
animation_scene = GetAnimationScene()
animation_scene.UpdateAnimationUsingDataTimeSteps()
for t in pvd_reader.TimestepValues:
    UpdatePipeline(time=t, proxy=pvd_reader)
display.RescaleTransferFunctionToDataRange(False, True)

animation_scene.PlayMode = "Snap To TimeSteps"  # discrete steps

async def animation_loop():
    if not pvd_reader.TimestepValues:
        return

    animation_scene.GoToFirst()
    for t in pvd_reader.TimestepValues:
        if not state.playing:
            break  # Stop if animation is paused
        print(f"Time {t:.2f} -> updating view")
        UpdatePipeline(time=t, proxy=pvd_reader)
        render_view.ViewTime = t
        display.RescaleTransferFunctionToDataRange(True, True)
        render_view.StillRender()
        ctrl.view_update()
        await asyncio.sleep(0.1)


@ctrl.add("on_server_ready")
def start_animation(**kwargs):
    global animation_task
    state.playing = True

    # If an animation is already running, cancel it first
    if animation_task and not animation_task.done():
        animation_task.cancel()

    animation_task = asyncio.create_task(animation_loop())


@ctrl.add("reset_camera")
def reset_camera():
    """Reset the camera to its initial position."""
    render_view.ResetCamera()


def reset_time():
    global animation_task
    state.playing = False

    if animation_task and not animation_task.done():
        animation_task.cancel()

    if pvd_reader.TimestepValues:
        state.time = 0
        render_view.ViewTime = pvd_reader.TimestepValues[0]
        UpdatePipeline(time=pvd_reader.TimestepValues[0], proxy=pvd_reader)
        render_view.StillRender()
        ctrl.view_update()
        update_view()


# -----------------------------------------------------------------------------
# Trame GUI layout
# -----------------------------------------------------------------------------
with SinglePageLayout(server) as layout:
    layout.title.set_text("Room Heating Simulation - ParaView Web")

    with layout.content:
        # Sidebar with some controls
        with vuetify.VNavigationDrawer(app=True, permanent=True, width="180"):
            vuetify.VListItemTitle("Controls")
            vuetify.VBtn(text=True, click=ctrl.reset_camera, children=["Reset Camera"])
            vuetify.VBtn(text=True, click=reset_time, children=["Reset Time"])
            vuetify.VBtn(
                text=True,
                click=start_animation,
                children=[vuetify.VIcon("mdi-play")]
            )

        # Main 2D/3D View
        vtk_view = pv.VtkRemoteView(render_view, ref="view")

    # Optional toolbar...

# After layout is built, set up the controller for view updates
ctrl.view_update = vtk_view.update

# -----------------------------------------------------------------------------
# Start the application
# -----------------------------------------------------------------------------
server.start()