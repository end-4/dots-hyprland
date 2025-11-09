Name:           Bibata-Modern-Classic
Version:        2.0.7
Release:        %autorelease
Summary:        Open source, compact, and material designed cursor set.

License:        GPL-3.0
URL:            https://github.com/ful1e5/Bibata_Cursor
Source0:        %{name}.tar.xz

BuildArch:      noarch

%description
Open source, compact, and material designed cursor set.

%prep
wget --content-disposition -q -N -P %{_sourcedir} %{url}/releases/download/v%{version}/Bibata-Modern-Classic.tar.xz
wget -q -O %{_buildrootdir}/LICENSE %{url}/raw/refs/heads/main/LICENSE
%setup -q -n %{name}

%build
:

%install
install -d -m 0755 %{buildroot}%{_iconsdir}/Bibata-Modern-Classic
cp -r * %{buildroot}%{_iconsdir}/Bibata-Modern-Classic

install -d -m 0755 %{buildroot}%{_licensedir}/%{name}
install -m 0644 %{_buildrootdir}/LICENSE %{buildroot}%{_licensedir}/%{name}/

%files
%{_iconsdir}/Bibata-Modern-Classic
%license %{_licensedir}/%{name}/LICENSE

%changelog
%autochangelog

