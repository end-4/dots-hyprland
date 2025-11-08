Name:           ttf-roboto-flex
Version:        3.200
Release:        %autorelease
Summary:        Roboto Flex

License:        OFL-1.1 
URL:            https://github.com/googlefonts/roboto-flex
Source0:        %{name}

BuildRequires:  fonts-rpm-macros
BuildArch:      noarch

%description
:

%prep
wget --content-disposition -q -N -P %{_sourcedir} %{url}/raw/refs/heads/main/fonts/RobotoFlex%5BGRAD,XOPQ,XTRA,YOPQ,YTAS,YTDE,YTFI,YTLC,YTUC,opsz,slnt,wdth,wght%5D.ttf
wget -q -O %{_sourcedir}/OFL.txt %{url}/raw/refs/heads/main/OFL.txt

%build
:

%install
install -d -m 0755 %{buildroot}%{_fontdir}
install -m 0644 %{_sourcedir}/RobotoFlex*ttf %{buildroot}%{_fontdir}

install -d -m 0755 %{buildroot}%{_licensedir}/%{name}
install -m 0644 %{_sourcedir}/OFL.txt %{buildroot}%{_licensedir}/%{name}/

%post
/usr/bin/fc-cache -fv >/dev/null 2>&1 || :

%postun
/usr/bin/fc-cache -fv >/dev/null 2>&1 || :

%files
%{_fontdir}/RobotoFlex*ttf
%license %{_licensedir}/%{name}/OFL.txt

%changelog
%autochangelog

