package main

import (
	"encoding/json"
	"fmt"
	"os"
	"unsafe"

	client "github.com/labi-le/hyprland-ipc-client"
)

var workspaces = make([]workspace, 0)
var activewindow = activeWindow{
	Title:     "",
	Class:     "",
	Workspace: 0,
}
var activeWorkspace = 0
var hypr = client.NewClient(os.Getenv("HYPRLAND_INSTANCE_SIGNATURE"))

func main() {
	setWorkspaces()
	setActiveWindow()
	writeOut()
	ed := &evHandler{}
	client.Subscribe(hypr, ed, client.EventActiveWindow, client.EventCreateWorkspace, client.EventDestroyWorkspace, client.EventMoveWorkspace, client.EventWorkspace)
}

func setActiveWindow() {
	aw, err := hypr.ActiveWindow()
	if err != nil {
		fmt.Println("can't get active window lul")
	}
	activewindow = activeWindow{
		Title:     aw.Title,
		Class:     aw.Class,
		Workspace: aw.Workspace.Id,
	}
	activeWorkspace = aw.Workspace.Id
}

func setWorkspaces() {
	mons, err := hypr.Monitors()
	if err != nil {
		fmt.Println("can't get monitors lul")
	}
	wrk, err := hypr.Workspaces()
	if err != nil {
		fmt.Println("can't get workspaces lul")
	}

	for _, m := range mons {
		if m.Focused {
			activeWorkspace = m.ActiveWorkspace.Id
			break
		}
	}

	workspaces = make([]workspace, len(wrk), len(wrk))
	for i, w := range wrk {
		workspaces[i] = workspace{
			ID:             w.Id,
			Populated:      w.Windows > 0,
			LeftPopulated:  hasWorkspaceAndIsPopulated(w.Id-1, wrk),
			RightPopulated: hasWorkspaceAndIsPopulated(w.Id+1, wrk),
		}
	}
}

func hasWorkspaceAndIsPopulated(id int, wrk []client.Workspace) bool {
	for _, w := range wrk {
		if w.Id == id && w.Windows > 0 {
			return true
		}
	}
	return false
}

func writeOut() {
	rd := retData{
		Workspaces:      workspaces,
		ActiveWindow:    activewindow,
		ActiveWorkspace: activeWorkspace,
	}
	js, err := json.Marshal(rd)
	if err != nil {
		fmt.Println("can't marshal lul")
	}
	fmt.Println(unsafe.String(unsafe.SliceData(js), len(js)))
}

type evHandler struct {
	client.DummyEvHandler
}

func (e *evHandler) Workspace(client.WorkspaceName)        { setWorkspaces(); writeOut() }
func (e *evHandler) FocusedMonitor(client.FocusedMonitor)  { setActiveWindow(); writeOut() }
func (e *evHandler) ActiveWindow(client.ActiveWindow)      { setActiveWindow(); writeOut() }
func (e *evHandler) Fullscreen(bool)                       {}
func (e *evHandler) MonitorRemoved(client.MonitorName)     { setWorkspaces(); writeOut() }
func (e *evHandler) MonitorAdded(client.MonitorName)       { setWorkspaces(); writeOut() }
func (e *evHandler) CreateWorkspace(client.WorkspaceName)  { setWorkspaces(); writeOut() }
func (e *evHandler) DestroyWorkspace(client.WorkspaceName) { setWorkspaces(); writeOut() }
func (e *evHandler) MoveWorkspace(client.MoveWorkspace)    { setWorkspaces(); writeOut() }
func (e *evHandler) ActiveLayout(client.ActiveLayout)      {}
func (e *evHandler) OpenWindow(client.OpenWindow)          {}
func (e *evHandler) CloseWindow(client.CloseWindow)        {}
func (e *evHandler) MoveWindow(client.MoveWindow)          {}
func (e *evHandler) OpenLayer(client.OpenLayer)            {}
func (e *evHandler) CloseLayer(client.CloseLayer)          {}
func (e *evHandler) SubMap(client.SubMap)                  {}

type retData struct {
	Workspaces      []workspace  `json:"workspaces"`
	ActiveWindow    activeWindow `json:"activewindow"`
	ActiveWorkspace int          `json:"activeworkspace"`
}

type workspace struct {
	ID             int  `json:"id"`
	Populated      bool `json:"populated"`
	LeftPopulated  bool `json:"leftPopulated"`
	RightPopulated bool `json:"rightPopulated"`
}

type activeWindow struct {
	Title     string `json:"title"`
	Class     string `json:"class"`
	Workspace int    `json:"workspace"`
}
