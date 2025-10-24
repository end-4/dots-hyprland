# Screenshot and screen recording tools
{ pkgs }:

{
  # Screenshot tools
  hyprshot = pkgs.hyprshot;
  slurp = pkgs.slurp;
  swappy = pkgs.swappy;

  # OCR for screenshots
  tesseract = pkgs.tesseract;

  # Tesseract language data
  #tesseract-data-eng = pkgs.tesseract4; # English language data

  # Screen recording
  wf-recorder = pkgs.wf-recorder;
}
