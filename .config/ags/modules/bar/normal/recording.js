import Widget from "resource:///com/github/Aylur/ags/widget.js";
import RecordingService from "../../../services/recording.js";

const RecordingIndicator = () => {
  return Widget.Label({
    className: "recording-indicator",
    label: "●",
    visible: false,
    setup: (self) => {
      self.setCss(`
        font-size: 22px;
        color: #c43737;
        margin: 0 6px;
        opacity: 0;
        transition: opacity 300ms ease;
      `);

      self.hook(RecordingService, () => {
        if (RecordingService.recording) {
          self.setCss(`
            font-size: 22px;
            color: #c43737;
            margin: 0 6px;
            opacity: 1;
            transition: opacity 300ms ease;
          `);
          self.visible = true;
        } else {
          self.setCss(`
            font-size: 22px;
            color: #c43737;
            margin: 0 6px;
            opacity: 0;
            transition: opacity 300ms ease;
          `);

          Utils.timeout(300, () => {
            self.visible = false;
          });
        }
      });
    },
  });
};

export default RecordingIndicator;
