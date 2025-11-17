# Original-Spec: https://copr-dist-git.fedorainfracloud.org/packages/solopasha/hyprland/hyprland-qt-support.git/plain/hyprland-qt-support.spec?h=master

Name:           hyprland-qt-support
Version:        0.1.0
Release:        %autorelease -b9
Summary:        A Qt6 Qml style provider for hypr* apps
License:        BSD-3-Clause
URL:            https://github.com/hyprwm/hyprland-qt-support
Source:         %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

# https://fedoraproject.org/wiki/Changes/EncourageI686LeafRemoval
ExcludeArch:    %{ix86}

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  qt6-rpm-macros

BuildRequires:  cmake(Qt6Quick)
BuildRequires:  cmake(Qt6QuickControls2)
BuildRequires:  cmake(Qt6Qml)

BuildRequires:  pkgconfig(hyprlang)

%description
%{summary}.

%prep
%autosetup -p1

%build
%cmake -DINSTALL_QMLDIR=%{_qt6_qmldir}
%cmake_build

%install
%cmake_install

%files
%license LICENSE
%doc README.md
%{_prefix}/lib/libhyprland-quick-style-impl.so
%{_prefix}/lib/libhyprland-quick-style.so
%{_qt6_qmldir}/org/hyprland/

%changelog
%autochangelog
