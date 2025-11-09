HYPR_DIR="local-pkgs/hyprland"
FT_DIR="local-pkgs/fonts-and-themes"
WIDGETS_DIR="local-pkgs/widgets"

function import_ebuild(){
	from_dir="$1"
	to_dir="$2"
	ename="$3"
	x sudo rm -rf "${ebuild_dir}/${to_dir}/${ename}"
	x sudo mkdir -p "${ebuild_dir}/${to_dir}/${ename}"
	v sudo cp ./sdata/dist-gentoo/${from_dir}/${ename}*.ebuild "${ebuild_dir}/${to_dir}/${ename}"
	v sudo ebuild "${ebuild_dir}/${to_dir}/${ename}/${ename}"*.ebuild digest
}

############### HYPRLAND
import_ebuild "${HYPR_DIR}" "dev-libs" "hyprgraphics"
import_ebuild "${HYPR_DIR}" "gui-libs" "hyprland-qt-support"
import_ebuild "${HYPR_DIR}" "gui-libs" "hyprland-qtutils"
import_ebuild "${HYPR_DIR}" "dev-libs" "hyprlang"
import_ebuild "${HYPR_DIR}" "dev-util" "hyprwayland-scanner"

############### FONTS AND THEMES
import_ebuild "${HYPR_DIR}" "dev-libs" "hyprgraphics"
import_ebuild "${FT_DIR}" "media-fonts" "gabarito"
import_ebuild "${FT_DIR}" "media-fonts" "material-symbols-variable"
import_ebuild "${FT_DIR}" "media-fonts" "readex-pro"
import_ebuild "${FT_DIR}" "media-fonts" "rubik-vf"
import_ebuild "${FT_DIR}" "media-fonts" "space-grotesk"
import_ebuild "${FT_DIR}" "kde-plasma" "breeze-plus"
import_ebuild "${FT_DIR}" "x11-themes" "darkly"
import_ebuild "${FT_DIR}" "media-fonts" "roboto-flex"

############### WIDGETS
import_ebuild "${WIDGETS_DIR}" "app-misc" "songrec"
