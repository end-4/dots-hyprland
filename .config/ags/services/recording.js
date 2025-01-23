import Service from "resource:///com/github/Aylur/ags/service.js";
import Utils from "resource:///com/github/Aylur/ags/utils.js";

class RecordingService extends Service {
  static {
    Service.register(
      this,
      { "recording-status": ["boolean"] },
      { recording: "boolean" },
    );
  }

  #recording = false;
  #checkInterval = null;

  constructor() {
    super();
    this.#initRecordingCheck();
  }

  #initRecordingCheck() {
    if (this.#checkInterval) {
      clearInterval(this.#checkInterval);
    }

    this.#checkInterval = setInterval(() => {
      this.#checkRecordingStatus();
    }, 2000);
  }

  #checkRecordingStatus() {
    try {
      const processCheck = Utils.exec("pgrep -x wf-recorder");
      const newStatus = processCheck.length > 0;

      if (newStatus !== this.#recording) {
        this.#recording = newStatus;
        this.changed("recording");
      }
    } catch {
      if (this.#recording) {
        this.#recording = false;
        this.changed("recording");
      }
    }
  }

  get recording() {
    return this.#recording;
  }

  destroy() {
    if (this.#checkInterval) {
      clearInterval(this.#checkInterval);
    }
  }
}

export default new RecordingService();
