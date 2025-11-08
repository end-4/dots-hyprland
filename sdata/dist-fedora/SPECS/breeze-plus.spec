Name:           breeze-plus
Version:        6.19.0
Release:        %autorelease
Summary:        Breeze theme with additional icons

License:        LGPL-2.1
URL:            https://github.com/mjkim0727/breeze-plus
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch

%description
Breeze icon theme with additional icons for applications not covered by the
official Breeze theme. Includes icons for Wine, third-party apps, and more.

%prep
wget --content-disposition -q -N -P %{_sourcedir} %{url}/archive/refs/tags/%{version}.tar.gz
%setup -q

%build
:

%install
install -d -m 0755 %{buildroot}%{_iconsdir}/breeze-plus
cp -r src/breeze-plus %{buildroot}%{_iconsdir}/
cp -r src/breeze-plus-dark %{buildroot}%{_iconsdir}/

install -d -m 0755 %{buildroot}%{_licensedir}/%{name}
install -m 0644 LICENSE %{buildroot}%{_licensedir}/%{name}/

%files
%{_iconsdir}/breeze-plus/
%{_iconsdir}/breeze-plus-dark/
%license %{_licensedir}/%{name}/LICENSE

%changelog
%autochangelog

