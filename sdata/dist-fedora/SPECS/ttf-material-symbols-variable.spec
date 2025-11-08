Name:           ttf-material-symbols-variable
Version:        4.0.0
Release:        %autorelease
Summary:        Material Design icons by Google (Material Symbols)

License:        Apache-2.0
URL:            https://github.com/google/material-design-icons
Source0:        %{name}-%{version}

BuildRequires:  fonts-rpm-macros
BuildArch:      noarch

%description
Google Material Symbols Rounded

%prep
wget --content-disposition -q -N -P %{_sourcedir} %{url}/raw/refs/heads/master/variablefont/MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf
wget -q -N -P %{_sourcedir} %{url}/raw/refs/heads/master/LICENSE

%build
:

%install
install -d -m 0755 %{buildroot}%{_fontdir}/variable-fonts
install -m 0644 %{_sourcedir}/MaterialSymbolsRounded*ttf %{buildroot}%{_fontdir}/variable-fonts/

install -d -m 0755 %{buildroot}%{_licensedir}/%{name}
install -m 0644 %{_sourcedir}/LICENSE %{buildroot}%{_licensedir}/%{name}/

%post
/usr/bin/fc-cache -fv >/dev/null 2>&1 || :

%postun
/usr/bin/fc-cache -fv >/dev/null 2>&1 || :

%files
%{_fontdir}/variable-fonts/MaterialSymbolsRounded*ttf
%license %{_licensedir}/%{name}/LICENSE

%changelog
%autochangelog

