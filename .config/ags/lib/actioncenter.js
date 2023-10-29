// Not yet used. For cool drag and drop stuff. Thanks DevAlien

const Toggles = {};
Toggles.Wifi = NetworkToggle;
Toggles.Bluetooth = BluetoothToggle;
Toggles.DND = DNDToggle;
Toggles.ThemeToggle = ThemeToggle;
Toggles.ProfileToggle = ProfileToggle;
// Toggles.Record = RecordToggle;
// Toggles.Airplane = AirplaneToggle;
// Toggles.DoNotDisturb = DoNotDisturbToggle;
const TARGET = [Gtk.TargetEntry.new("text/plain", Gtk.TargetFlags.SAME_APP, 0)];

export class ActionCenter extends Gtk.Box {
  static {
    GObject.registerClass({
      GTypeName: 'ActionCenter',
      Properties: {

      },
    }, this);
  }

  constructor({ className = "ActionCenter", toggles, ...rest }) {
    super(rest);
    this.toggles = Toggles
    this.currentToggles = Settings.getSetting("toggles", []);
    this.mainFlowBox = this._setupFlowBox(className + QSView.editing && className + "Editing");
    this.mainFlowBox.connect("drag_motion", this._dragMotionMain);
    this.mainFlowBox.connect("drag_drop", this._dragDropMain);
    this._dragged = {};
    this._draggedExtra = {};

    this._dragged;
    this._currentPosition = 0;
    this._orderedState;
    this._draggedName;

    this.updateList(toggles, this.mainFlowBox)

    this.set_orientation(Gtk.Orientation.VERTICAL);
    this.add(this.mainFlowBox)
    this.mainFlowBox.set_size_request(1, 30)
    if (QSView.editing) {
      this.extraFlowBox = this._setupFlowBox(className);
      this.extraFlowBox.connect("drag_motion", this._dragMotionExtra);
      this.extraFlowBox.connect("drag_drop", this._dragDropExtra);
      this.updateList(this._getExtraToggles(), this.extraFlowBox)
      this.add(Box({
        vertical: true,
        children: [
          Label("Extra widgets"),
          Label("Drop here to remove or drag from here to add"),
          this.extraFlowBox
        ]
      }))
    }
  }

  _getExtraToggles() {
    let toggles = { ...this.toggles }
    this.currentToggles.map(t => {
      if (toggles[t]) {
        delete toggles[t];
      }
    });
    return Object.keys(toggles);
  }

  _setupFlowBox(className) {
    const flowBox = new Gtk.FlowBox();
    flowBox.set_valign(Gtk.Align.FILL);
    flowBox.set_min_children_per_line(2);
    flowBox.set_max_children_per_line(2);
    flowBox.set_selection_mode(Gtk.SelectionMode.NONE);
    flowBox.get_style_context().add_class(className);
    flowBox.set_homogeneous(true);
    flowBox.drag_dest_set(Gtk.DestDefaults.ALL, TARGET, Gdk.DragAction.COPY);

    return flowBox;
  }

  createWidget = (name, index, type) => {
    const editSetup = (widget) => {
      widget.drag_source_set(
        Gdk.ModifierType.BUTTON1_MASK,
        TARGET,
        Gdk.DragAction.COPY
      );

      widget.connect("drag-begin", (w, context) => {
        const widgetContainer = widget.get_parent();

        Gtk.drag_set_icon_surface(context, createSurfaceFromWidget(widgetContainer));
        this._dragged = {
          widget: widgetContainer.get_parent().get_parent(),
          container: widgetContainer,
          name: name,
          currentPosition: type === "Main" ? index : null,
          currentPositionExtra: type === "Extra" ? index : null,
          from: type,
        }
        widgetContainer.get_style_context().add_class("hidden");
        if (type !== "Main") {
          this.extraFlowBox.remove(this._dragged.widget);
        }


        return true;
      });
      widget.connect("drag-failed", () => {
        this.updateList(Settings.getSetting("toggles"), this.mainFlowBox)
        this.updateList(this._getExtraToggles(), this.extraFlowBox)
      });
    }

    let row = new Gtk.FlowBoxChild({ visible: true });
    row.add(Toggles[name]({ setup: QSView.editing && editSetup, QSView: QSView }));
    row._index = index;
    row._name = name;
    return row;
  }

  updateList(toggles, flowBox) {
    let type = flowBox === this.mainFlowBox ? "Main" : "Extra"
    var childrenBox = flowBox.get_children();
    childrenBox.forEach((element) => {
      flowBox.remove(element);
      element.destroy();
    });

    if (!toggles) return;

    toggles.forEach((name, i) => {
      if (Toggles[name])
        flowBox.add(this.createWidget(name, i, type));
    });
    flowBox.show_all();
  }


  _dragMotionMain = (widget, context, x, y, time) => {
    if (this._dragged.currentPositionExtra !== null) {
      this._dragged.currentPositionExtra = null;
      if (this._isChild(this.extraFlowBox, this._dragged.widget)) {
        this.extraFlowBox.remove(this._dragged.widget);
      }
    }
    const children = this.mainFlowBox.get_children();
    const sampleItem = children[0];
    const sampleWidth = sampleItem.get_allocation().width;
    const sampleHeight = sampleItem.get_allocated_height();
    const perLine = Math.floor(this.mainFlowBox.get_allocation().width / sampleWidth);
    const pos = Math.floor(y / sampleHeight) * perLine + Math.floor(x / sampleWidth);
    if (pos >= children.length && pos !== 0) return false;

    if (this._dragged.currentPosition === null) {
      this.mainFlowBox.insert(this._dragged.widget, pos);

      this._dragged.currentPosition = pos;
    } else if (this._dragged.currentPosition !== pos) {
      if (this._isChild(this.mainFlowBox, this._dragged.widget)) {
        this.mainFlowBox.remove(this._dragged.widget);
      }

      this.mainFlowBox.insert(this._dragged.widget, pos);

      this._dragged.currentPosition = pos;
    }

    return true;
  }

  _dragDropMain = () => {
    if (this._dragged.from !== "Main") {
      this.currentToggles.splice(this._dragged.currentPosition, 0, this._dragged.name);
    } else {
      const indexCurrentToggle = this.currentToggles.indexOf(this._dragged.name);
      this.currentToggles.splice(indexCurrentToggle, 1);
      this.currentToggles.splice(this._dragged.currentPosition, 0, this._dragged.name);
    }

    Settings.setSetting("toggles", this.currentToggles);
    this._dragged.container.get_style_context().remove_class("hidden");
    return true;
  }

  _dragDropExtra = () => {
    if (this._dragged.from === "Main") {
      const indexCurrentToggle = this.currentToggles.indexOf(this._dragged.name);
      this.currentToggles.splice(indexCurrentToggle, 1);
    }

    Settings.setSetting("toggles", this.currentToggles);
    this._dragged.container.get_style_context().remove_class("hidden");
    return true;
  }

  _dragMotionExtra = (widget, context, x, y, time) => {
    if (this._dragged.currentPosition !== null) {
      this._dragged.currentPosition = null;
      if (this._isChild(this.mainFlowBox, this._dragged.widget)) {
        this.mainFlowBox.remove(this._dragged.widget);
      }
    }

    const children = this.extraFlowBox.get_children();
    const sampleItem = children[0];
    let pos = 0;
    if (sampleItem) {
      const sampleWidth = sampleItem.get_allocation().width;
      const sampleHeight = sampleItem.get_allocated_height();
      const perLine = Math.floor(this.extraFlowBox.get_allocation().width / sampleWidth);
      pos = Math.floor(y / sampleHeight) * perLine + Math.floor(x / sampleWidth);
    }

    if (pos >= children.length && pos !== 0) return false;

    if (this._dragged.currentPositionExtra === null) {
      this.extraFlowBox.insert(this._dragged.widget, pos);

      this._dragged.currentPositionExtra = pos;
    }

    if (this._dragged.currentPositionExtra !== pos) {
      if (this._isChild(this.extraFlowBox, this._dragged.widget)) {
        this.extraFlowBox.remove(this._dragged.widget);
      }

      this.extraFlowBox.insert(this._dragged.widget, pos);

      this._dragged.currentPositionExtra = pos;
    }

    return true;
  }

  _isChild(container, widget) {
    let found = false;
    container.get_children().forEach((c) => {
      if (c === widget) found = true;
    })
    return found;
  }
}