Name:           JetBrainsMonoNerdFont-Regular
Version:        1.2
Release:        %autorelease
Summary:        JetBrainsMonoNerdFonts (TrueType Outlines) (Regulear)

License:        MIT
URL:            https://github.com/Zhaopudark/JetBrainsMonoNerdFonts
Source0:        %{name}

BuildRequires:  fonts-rpm-macros
BuildArch:      noarch

%description
An auto-updated compiling version of JetBrains Mono that has been patched with Nerd Fonts.

%prep
wget --content-disposition -q -N -P %{_sourcedir} %{url}/releases/download/v%{version}/JetBrainsMonoNerdFont-Regular-v%{version}.ttf
wget -q -P %{_sourcedir} %{url}/raw/refs/heads/main/LICENSE

%build
:

%install
install -d -m 0755 %{buildroot}%{_fontdir}
install -m 0644 %{_sourcedir}/JetBrainsMonoNerdFont*ttf %{buildroot}%{_fontdir}

install -d -m 0755 %{buildroot}%{_licensedir}/%{name}
install -m 0644 %{_sourcedir}/LICENSE %{buildroot}%{_licensedir}/%{name}/

%post
/usr/bin/fc-cache -fv >/dev/null 2>&1 || :

%postun
/usr/bin/fc-cache -fv >/dev/null 2>&1 || :

%files
%{_fontdir}/JetBrainsMonoNerdFont*ttf
%license %{_licensedir}/%{name}/LICENSE

%changelog
%autochangelog

