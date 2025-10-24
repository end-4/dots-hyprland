# Audio-related packages
{ pkgs }:

{
  # Audio packages
  cava = pkgs.cava;
  pavucontrol-qt = pkgs.lxqt.pavucontrol-qt;
  wireplumber = pkgs.wireplumber;
  libdbusmenu-gtk3 = pkgs.libdbusmenu-gtk3;
  playerctl = pkgs.playerctl;
}
