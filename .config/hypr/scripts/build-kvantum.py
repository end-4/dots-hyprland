import json
import os

# Define the path to the colors.json file
colors_json_path = os.path.expanduser("~/.cache/wal/colors.json")

# Define the directory and file paths for the Kvantum theme
kvantum_dir = os.path.expanduser("~/.config/Kvantum/Pywal")
kvantum_file_path = os.path.join(kvantum_dir, "Pywal.kvconfig")

# Create the Kvantum directory if it doesn't exist
os.makedirs(kvantum_dir, exist_ok=True)

# Read colors from the colors.json file
with open(colors_json_path, 'r') as f:
    colors_data = json.load(f)

# Extract colors
color0 = colors_data["colors"]["color0"]
color2 = colors_data["colors"]["color2"]
color7 = colors_data["colors"]["color7"]
color8 = colors_data["colors"]["color8"]
color12 = colors_data["colors"]["color4"]
color15 = colors_data["colors"]["color7"]

# Function to lighten or darken a color
def lighten(color, percent):
    color = color.lstrip('#')
    lv = len(color)
    return '#' + ''.join([hex(min(int(color[i:i + lv // 3], 16) + int(255 * percent / 100), 255)).lstrip('0x').rjust(2, '0') for i in range(0, lv, lv // 3)])

def darken(color, percent):
    color = color.lstrip('#')
    lv = len(color)
    return '#' + ''.join([hex(max(int(color[i:i + lv // 3], 16) - int(255 * percent / 100), 0)).lstrip('0x').rjust(2, '0') for i in range(0, lv, lv // 3)])

# Create the Kvantum theme configuration content
kvantum_config_content = f"""
[%General]
author=Vince Liuice, based on KvAdapta by Tsu Jan
comment=An uncomplicated theme inspired by the Materia GTK theme
x11drag=menubar_and_primary_toolbar
alt_mnemonic=true
left_tabs=false
attach_active_tab=false
mirror_doc_tabs=false
group_toolbar_buttons=true
toolbar_item_spacing=0
toolbar_interior_spacing=2
spread_progressbar=true
composite=true
menu_shadow_depth=16
spread_menuitems=true
tooltip_shadow_depth=0
splitter_width=1
scroll_width=9
scroll_arrows=false
scroll_min_extent=60
slider_width=2
slider_handle_width=23
slider_handle_length=22
tickless_slider_handle_size=22
center_toolbar_handle=true
check_size=24
textless_progressbar=false
progressbar_thickness=2
menubar_mouse_tracking=true
toolbutton_style=1
double_click=false
translucent_windows=false
blurring=false
popup_blurring=false
vertical_spin_indicators=false
spin_button_width=24
fill_rubberband=false
merge_menubar_with_toolbar=true
small_icon_size=16
large_icon_size=32
button_icon_size=16
toolbar_icon_size=16
combo_as_lineedit=true
animate_states=true
button_contents_shift=false
combo_menu=true
hide_combo_checkboxes=true
combo_focus_rect=false
groupbox_top_label=true
inline_spin_indicators=true
joined_inactive_tabs=false
layout_spacing=6
layout_margin=9
scrollbar_in_view=true
transient_scrollbar=true
transient_groove=true
submenu_overlap=0
tooltip_delay=0
tree_branch_line=true
no_window_pattern=false
opaque=kaffeine,kmplayer,subtitlecomposer,kdenlive,vlc,smplayer,smplayer2,avidemux,avidemux2_qt4,avidemux3_qt4,avidemux3_qt5,kamoso,QtCreator,VirtualBox,trojita,dragon,digikam
reduce_window_opacity=0
respect_DE=true
scrollable_menu=false
submenu_delay=150
no_inactiveness=false
reduce_menu_opacity=0
click_behavior=0
contrast=1.00
dialog_button_layout=0
intensity=1.00
saturation=1.00
shadowless_popup=false
drag_from_buttons=false
menu_blur_radius=0
tooltip_blur_radius=0

[GeneralColors]
window.color={color0}
base.color={color0}
alt.base.color={lighten(color8, 10)}
button.color={color12}
light.color={darken(color8, 3)}
mid.light.color={darken(color8, 5)}
dark.color={lighten(color0, 2)}
mid.color={lighten(color0, 3)}
highlight.color={color12}
inactive.highlight.color={color12}
text.color={color15}
window.text.color={color15}
button.text.color={color15}
disabled.text.color={color8}
tooltip.text.color={color15}
highlight.text.color={color15}
link.color={color2}
link.visited.color={color2}
progress.indicator.text.color={color15}

[Hacks]
transparent_ktitle_label=true
transparent_dolphin_view=true
transparent_pcmanfm_sidepane=true
blur_translucent=false
transparent_menutitle=true
respect_darkness=true
kcapacitybar_as_progressbar=true
force_size_grip=true
iconless_pushbutton=true
iconless_menu=false
disabled_icon_opacity=100
lxqtmainmenu_iconsize=16
normal_default_pushbutton=true
single_top_toolbar=true
tint_on_mouseover=0
transparent_pcmanfm_view=true
no_selection_tint=true
transparent_arrow_button=true
middle_click_scroll=false
opaque_colors=false
kinetic_scrolling=false
scroll_jump_workaround=true
centered_forms=false
noninteger_translucency=false
style_vertical_toolbars=false
blur_only_active_window=true

[PanelButtonCommand]
frame=true
frame.element=button
frame.top=6
frame.bottom=6
frame.left=6
frame.right=6
interior=true
interior.element=button
indicator.size=8
text.normal.color={color15}
text.focus.color={color15}
text.press.color={color15}
text.toggle.color={color15}
text.shadow=0
text.margin=4
text.iconspacing=4
indicator.element=arrow
frame.expansion=0

[PanelButtonTool]
inherits=PanelButtonCommand
text.normal.color={color15}
text.focus.color={color15}
text.press.color={color15}
text.toggle.color={color15}
text.bold=false
indicator.element=arrow
indicator.size=0
frame.expansion=0

[ToolbarButton]
frame=true
frame.element=tbutton
interior.element=tbutton
frame.top=16
frame.bottom=16
frame.left=16
frame.right=16
indicator.element=tarrow
text.normal.color={color15}
text.focus.color={color15}
text.press.color={color15}
text.toggle.color={color15}
text.bold=false
frame.expansion=32

[Dock]
inherits=PanelButtonCommand
interior.element=dock
frame.element=dock
frame.top=1
frame.bottom=1
frame.left=1
frame.right=1
text.normal.color={color15}

[DockTitle]
inherits=PanelButtonCommand
frame=false
interior=false
text.normal.color={color15}
text.focus.color={color15}
text.bold=false

[IndicatorSpinBox]
inherits=PanelButtonCommand
frame=true
interior=true
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2
indicator.element=spin
indicator.size=8
text.normal.color={color15}
text.margin.top=2
text.margin.bottom=2
text.margin.left=2
text.margin.right=2

[RadioButton]
inherits=PanelButtonCommand
frame=false
interior.element=radio
text.normal.color={color15}
text.focus.color={color15}
min_width=+0.3font
min_height=+0.3font

[CheckBox]
inherits=PanelButtonCommand
frame=false
interior.element=checkbox
text.normal.color={color15}
text.focus.color={color15}
min_width=+0.3font
min_height=+0.3font

[Focus]
inherits=PanelButtonCommand
frame=true
frame.element=focus
frame.top=2
frame.bottom=2
frame.left=2
frame.right=2
frame.patternsize=14

[GenericFrame]
inherits=PanelButtonCommand
frame=true
interior=false
frame.element=common
interior.element=common
frame.top=1
frame.bottom=1
frame.left=1
frame.right=1

[LineEdit]
inherits=PanelButtonCommand
frame.element=lineedit
interior.element=lineedit
frame.top=6
frame.bottom=6
frame.left=6
frame.right=6
text.margin.top=2
text.margin.bottom=2
text.margin.left=2
text.margin.right=2

[ToolbarLineEdit]
frame.element=lineedit
interior.element=lineedit

[DropDownButton]
inherits=PanelButtonCommand
indicator.element=arrow-down

[IndicatorArrow]
indicator.element=arrow
indicator.size=8

[ToolboxTab]
inherits=PanelButtonCommand
text.normal.color={color15}
text.press.color={color15}
text.focus.color={color15}

[Tab]
inherits=PanelButtonCommand
interior.element=tab
text.margin.left=8
text.margin.right=8
text.margin.top=3
text.margin.bottom=3

[Frame]
inherits=PanelButtonCommand
frame=true
interior=true
frame.top=1
frame.bottom=1
frame.left=1
frame.right=1
frame.patternsize=14

[Dialog]
inherits=GenericFrame

[Menu]
inherits=PanelButtonCommand
frame.element=menu
interior.element=menu
text.margin.left=4
text.margin.right=4
text.margin.top=2
text.margin.bottom=2
frame.patternsize=16

[SubMenu]
inherits=Menu

[MenuItem]
inherits=PanelButtonCommand
frame=false
interior=false
text.normal.color={color15}
text.focus.color={color15}
text.press.color={color15}
text.toggle.color={color15}

[MenuButton]
inherits=PanelButtonCommand

[DockToolButton]
inherits=PanelButtonCommand
frame.element=dock

[Button]
inherits=PanelButtonCommand
frame.element=button
interior.element=button

[PushButton]
inherits=PanelButtonCommand
frame.element=pushbutton
interior.element=pushbutton

[FlatButton]
inherits=PanelButtonCommand
frame=false
interior=false

[FrameButton]
inherits=PanelButtonCommand
frame.element=framebutton
interior.element=framebutton

[ComboBox]
inherits=PanelButtonCommand
indicator.element=combo

[ComboBoxWithLines]
inherits=PanelButtonCommand
indicator.element=combo
frame.patternsize=16

[Slider]
inherits=PanelButtonCommand
frame=false
interior.element=slider

[TitleBar]
inherits=PanelButtonCommand
frame.element=titlebar
interior.element=titlebar

[SpinBox]
inherits=PanelButtonCommand
indicator.element=spin

[ToolButton]
inherits=PanelButtonCommand
frame.element=toolbutton
interior.element=toolbutton

[GroupBox]
inherits=PanelButtonCommand
frame.element=groupbox
interior.element=groupbox

[ProgressBar]
inherits=PanelButtonCommand
frame=false
interior.element=progress
indicator.size=2
indicator.element=progress

[Handle]
inherits=PanelButtonCommand
frame=false
interior.element=handle

[WidgetSeparator]
inherits=PanelButtonCommand
frame.element=separator
interior.element=separator

[MainWindow]
inherits=PanelButtonCommand
frame.element=mainwindow
interior.element=mainwindow
indicator.element=mainwindow

[TabWidget]
inherits=PanelButtonCommand
frame.element=tabwidget
interior.element=tabwidget
indicator.element=tabwidget

[ToolBar]
inherits=PanelButtonCommand
frame.element=toolbar
interior.element=toolbar
indicator.element=toolbar

[ToolBarFrame]
inherits=PanelButtonCommand
frame.element=toolbarframe
interior.element=toolbarframe

[ScrollArea]
inherits=PanelButtonCommand
frame.element=scrollarea
interior.element=scrollarea

[ScrollBar]
inherits=PanelButtonCommand
frame.element=scrollbar
interior.element=scrollbar
indicator.element=scrollbar

[ScrollBarHandle]
inherits=PanelButtonCommand
frame.element=scrollbarhandle
interior.element=scrollbarhandle

[ScrollView]
inherits=PanelButtonCommand
frame.element=scrollview
interior.element=scrollview

[Splitter]
inherits=PanelButtonCommand
frame.element=splitter
interior.element=splitter
indicator.element=splitter

[ToolBox]
inherits=PanelButtonCommand
frame.element=toolbox
interior.element=toolbox
indicator.element=toolbox

[ToolButtonMenuItem]
inherits=PanelButtonCommand
frame.element=toolbuttonmenuitem
interior.element=toolbuttonmenuitem

[ToolButtonPanel]
inherits=PanelButtonCommand
frame.element=toolbuttonpanel
interior.element=toolbuttonpanel
indicator.element=toolbuttonpanel

[ToolButtonTool]
inherits=PanelButtonCommand
frame.element=toolbuttontool
interior.element=toolbuttontool

[ToolButtonToolPanel]
inherits=PanelButtonCommand
frame.element=toolbuttontoolpanel
interior.element=toolbuttontoolpanel
indicator.element=toolbuttontoolpanel

[Tooltip]
inherits=PanelButtonCommand
frame.element=tooltip
interior.element=tooltip

[ProgressBarStyle]
inherits=PanelButtonCommand
frame=false
interior.element=progress
indicator.element=progress
text.normal.color={color15}
text.focus.color={color15}

[SplitHandle]
inherits=PanelButtonCommand
frame.element=splitter
interior.element=splitter
indicator.element=splitter

[ScrollbarHandle]
inherits=PanelButtonCommand
frame.element=scrollbarhandle
interior.element=scrollbarhandle
indicator.element=scrollbarhandle

[Tooltip]
inherits=PanelButtonCommand
frame.element=tooltip
interior.element=tooltip
text.normal.color={color15}
text.focus.color={color15}

[SplitterHandle]
inherits=PanelButtonCommand
frame.element=splitter
interior.element=splitter
indicator.element=splitter
"""

# Write the Kvantum theme configuration to the file
with open(kvantum_file_path, 'w') as f:
    f.write(kvantum_config_content)

print(f"Kvantum theme configuration saved to: {kvantum_file_path}")
