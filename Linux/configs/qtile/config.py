###################
#     Imports     #
###################

import os
import subprocess
import colors
from libqtile import bar, extension, hook, layout, qtile, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
from qtile_extras import widget
from qtile_extras.widget.decorations import BorderDecoration

#####################
#     Autostart     #
#####################

@hook.subscribe.startup_once
def autostart():
    home = os.path.expanduser('~/.scripts/autostart.sh')
    subprocess.Popen([home])

####################
#     Defaults     #
####################

# Keys
alt = "mod1"
mod = "mod4"

# Apps
myTerm = ""
FileManager = ""

# Colors
color_widgets = colors.widgets
color_ui = colors.ui

###########################
#     Keyboard layout     #
###########################

keyboard = widget.KeyboardLayout(configured_keyboards=['us', 'ru'])

########################
#     Key bindings     #
########################

keys = [
    # System keybindings
    Key([mod], "Left", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod], "Right", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod], "Down", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod], "Up", lazy.layout.shuffle_up(), desc="Move window up"),
    Key([alt], "Shift_L",  lazy.widget["keyboardlayout"].next_keyboard(), desc="change keyboard layout"),
    Key([mod], "f", lazy.window.toggle_floating(), desc="Toggle floating on the focused window"),
    Key([mod, "shift"], "Return", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
    Key([mod, "shift"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "shift"], "e", lazy.shutdown(), desc="Shutdown Qtile"), 
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    # Audio
    Key([mod], "Page_Up", lazy.spawn("pamixer --increase 5"), desc="increase volume by 5%"),
    Key([mod], "Page_Down", lazy.spawn("pamixer --decrease 5"), desc="decrease volume by 5%"),
    # Applications
    Key([mod, "shift"], "m", lazy.spawn("./.scripts/powermenu.sh"), desc="Rofi powermenu"),
    Key([mod], "p", lazy.spawn("flameshot gui"), desc="flameshot capture"),
    Key([mod], "b", lazy.spawn("firefox"), desc="Firefox browser"),
    Key([mod], "Return", lazy.spawn(myTerm), desc="Alacritty"),
    Key([mod], "e", lazy.spawn(FileManager), desc="nemo"),
]

##################################
#     Qtile panel workspaces     #
##################################

groups = []
group_names = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

group_labels = [" ", " ", " ", " ", " ", " ", " ", " ", " ", " "]

group_layouts = ["columns", "columns", "columns", "columns", "columns", "columns", "columns", "columns", "columns", "columns"]

for i in range(len(group_names)):
    groups.append(
        Group(
            name=group_names[i],
            layout=group_layouts[i].lower(),
            label=group_labels[i],
        ))

for i in groups:
    keys.extend(
        [
            # mod1 + letter of group = switch to group
            Key([mod], i.name, lazy.group[i.name].toscreen(), desc="Switch to group {}".format(i.name)),
            # mod1 + shift + letter of group = move focused window to group
            Key([mod, "shift"], i.name, lazy.window.togroup(i.name, switch_group=False), desc="Move focused window to group {}".format(i.name)),
        ]
    )

##################
#     Layout     #
##################

layout_theme = {"border_width": 1,
                "margin": 5,
                "border_focus": color_ui[1],
                "border_normal": color_ui[0],
                }

floating_layout = layout.Floating(**layout_theme,
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="steam"),  # steam
        Match(wm_class="lutris"),  # lutris
        Match(wm_class="virt-manager"),  # qemu
        Match(wm_class="nemo"),  # nemo
        Match(wm_class="transmission-gtk"),  # torrent
        Match(wm_class="openrgb"),  # rgb
        Match(wm_class="blueman-manager"),  # bluetooth manager
        Match(wm_class="lxappearance"),  # lxappearance
        Match(wm_class="pavucontrol"),  # audio
        Match(wm_class="file-roller"), # archivator
        Match(wm_class="Alacritty"), # terminal
        Match(wm_class="Gthumb"), # Photo viewer
    ]
)

layouts = [
    layout.Bsp(**layout_theme),
]

############################
#     Widgets defaults     #
############################

widget_defaults = dict(
    font="SpaceMonoNerd Font Bold",
    fontsize=12,
    padding=3,
    bacikground = color_widgets[0],
)
extension_defaults = widget_defaults.copy()

##################################
#     widgets shown on panel     #
##################################

widget_list = [

        widget.GroupBox(
            borderwidth = 1,
            highlight_method = 'block',
            block_highlight_text_color = color_widgets[3],
            this_current_screen_border = color_widgets[1], 
            rounded=True,
        ),

        widget.TextBox(
            text = '|',
            foreground = color_widgets[2],
            padding = 2,
            fontsize = 16,
            ),

        widget.Prompt(),

        widget.WindowName(
            max_chars=30,
            foreground = color_widgets[2],
        ),

        widget.Systray(padding = 3),

        widget.TextBox(
            text = '|',
            foreground = color_widgets[2],
            padding = 2,
            fontsize = 16,
        ),

        widget.Net(
            interface = "enp5s0",
            format = '{down:.0f}{down_suffix} ↓↑ {up:.0f}{up_suffix}',
        	foreground = color_widgets[3],
        ),

        widget.Spacer(length = 8),

        widget.Volume(
        foreground = color_widgets[3],
        fmt = ' : {}',
        ),

        widget.Spacer(length = 8),

        widget.KeyboardLayout(
            configured_keyboards = ['us','ru'],
            foreground = color_widgets[3],
            fmt = '⌨ : {}',
        ),

        widget.Spacer(length = 8),

        widget.Clock(
            foreground = color_widgets[3],
            format = "⏱ %a, %b %d - %H:%M",
        ),

        widget.Spacer(length = 8),
]

###################
#     Screens     #
###################

screens = [
    
    Screen(
        bottom = bar.Bar(
            widget_list,
            32,
            border_color = color_ui[3],
            margin = 5,
        ),
        # wallpaper = '', # Wallpaper Photo
        # wallpaper_mode = 'fill', # Wallpaper mode
    ),
    
]

#################################
#     Drag floating windows     #
#################################

mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

############################
#     General settings     #
############################

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True
auto_minimize = True
wl_input_rules = None
wmname = "LG3D"
