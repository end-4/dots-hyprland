Name:           otf-SpaceGrotesk
Version:        2.0.0
Release:        %autorelease
Summary:        Space Grotesk: a proportional variant of the original fixed-width Space Mono family

License:        OFL-1.1 
URL:            https://github.com/floriankarsten/space-grotesk
Source0:        %{name}-%{version}

BuildRequires:  fonts-rpm-macros
BuildArch:      noarch

%description
Space Grotesk is a proportional sans-serif typeface variant based on Colophon Foundry's fixed-width Space Mono family (2016). 
Originally designed by Florian Karsten in 2018, 
Space Grotesk retains the monospace's idiosyncratic details while optimizing for improved readability at non-display sizes.

%prep
wget --content-disposition -q -N -P %{_sourcedir} %{url}/releases/download/%{version}/SpaceGrotesk-%{version}.zip
unzip %{_sourcedir}/SpaceGrotesk-%{version}.zip

%build
:

%install
install -d -m 0755 %{buildroot}%{_fontdir}
install -m 0644 %{_buildrootdir}/SpaceGrotesk-%{version}/otf/SpaceGrotesk*otf %{buildroot}%{_fontdir}

install -d -m 0755 %{buildroot}%{_licensedir}/%{name}
install -m 0644 %{_buildrootdir}/SpaceGrotesk-%{version}/OFL.txt %{buildroot}%{_licensedir}/%{name}/

%post
/usr/bin/fc-cache -fv >/dev/null 2>&1 || :

%postun
/usr/bin/fc-cache -fv >/dev/null 2>&1 || :

%files
%{_fontdir}/SpaceGrotesk*otf
%license %{_licensedir}/%{name}/OFL.txt

%changelog
%autochangelog

