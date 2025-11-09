%global commit0 e337a5f69a9bea30e58d05bd40184d79cc099628
%global shortcommit0 %(c=%{commit0}; echo ${c:0:7})
%global bumpver 100

Name:           ttf-rubik-variable
Version:        1.0%{?bumpver:^%{bumpver}.git%{shortcommit0}}
Release:        %autorelease
Summary:        Rubik fonts variable

License:        OFL-1.1
URL:            https://github.com/googlefonts/rubik
Source0:        rubik-%{shortcommit0}.tar.gz

BuildRequires:  fonts-rpm-macros
BuildArch:      noarch

%description
:

%prep
wget --content-disposition -q -N -P %{_sourcedir} https://codeload.github.com/googlefonts/rubik/tar.gz/%{shortcommit0}
%setup -q -n rubik-%{shortcommit0}

%build
:

%install
install -d -m 0755 %{buildroot}%{_fontdir}/variable-fonts
install -m 0644 fonts/variable/Rubik*ttf %{buildroot}%{_fontdir}/variable-fonts/

install -d -m 0755 %{buildroot}%{_licensedir}/%{name}
install -m 0644 OFL.txt %{buildroot}%{_licensedir}/%{name}/

%post
/usr/bin/fc-cache -fv >/dev/null 2>&1 || :

%postun
/usr/bin/fc-cache -fv >/dev/null 2>&1 || :

%files
%{_fontdir}/variable-fonts/Rubik*ttf
%license %{_licensedir}/%{name}/OFL.txt

%changelog
%autochangelog

