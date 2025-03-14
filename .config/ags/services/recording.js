import Service from "resource:///com/github/Aylur/ags/service.js";
import Utils from "resource:///com/github/Aylur/ags/utils.js";

class RecordingService extends Service {
  static {
    Service.register(this, { "recording-status": ["boolean"] }, { recording: "boolean" });
  }

  #recording = false;

  constructor() {
    super();
    this.#checkRecordingStatus();
    this.interval = Utils.interval(3000, this.#checkRecordingStatus.bind(this));
  }

  #checkRecordingStatus() {
    const isRunning = Utils.exec("pgrep -x wf-recorder").trim() !== "";
    if (isRunning !== this.#recording) {
      this.#recording = isRunning;
      this.changed("recording");
    }
  }

  get recording() {
    return this.#recording;
  }
}

export default new RecordingService();
