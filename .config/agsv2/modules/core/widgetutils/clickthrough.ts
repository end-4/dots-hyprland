import { Gtk } from 'astal/gtk3';
import Cairo from 'gi://cairo?version=1.0';

export const dummyRegion = new Cairo.Region();
export const enableClickthrough = (self: Gtk.Widget) => self.input_shape_combine_region(dummyRegion);
