%global commit0 1f3fb39d6449eefa880543f109f33ede0cd4064f
%global shortcommit0 %(c=%{commit0}; echo ${c:0:7})
%global bumpver 100

Name:           ttf-gabarito
Version:        1.000%{?bumpver:^%{bumpver}.git%{shortcommit0}}
Release:        %autorelease
Summary:        Gabarito Font

License:        OFL-1.1 
URL:            https://github.com/naipefoundry/gabarito
Source0:        gabarito-%{shortcommit0}.tar.gz

BuildRequires:  fonts-rpm-macros
BuildArch:      noarch

%description
Gabarito is a light-hearted geometric sans typeface with 6 weights ranging from Regular to Black originally designed for an online learning platform in Brazil.

%prep
wget --content-disposition -q -N -P %{_sourcedir} https://codeload.github.com/naipefoundry/gabarito/tar.gz/%{shortcommit0}
%setup -q -n gabarito-%{shortcommit0}

%build
:

%install
install -d -m 0755 %{buildroot}%{_fontdir}
install -m 0644 fonts/ttf/Gabarito*.ttf %{buildroot}%{_fontdir}

install -d -m 0755 %{buildroot}%{_licensedir}/%{name}
install -m 0644 OFL.txt %{buildroot}%{_licensedir}/%{name}/

%post
/usr/bin/fc-cache -fv >/dev/null 2>&1 || :

%postun
/usr/bin/fc-cache -fv >/dev/null 2>&1 || :

%files
%{_fontdir}/Gabarito*ttf
%license %{_licensedir}/%{name}/OFL.txt

%changelog
%autochangelog

