# Original-Spec: https://copr-dist-git.fedorainfracloud.org/packages/errornointernet/quickshell/quickshell-git.git/plain/quickshell-git.spec?h=master

%global commit      e65259d68edc034905da477b6c1a349e89e2aa8d
%global shortcommit %(c=%{commit}; echo ${c:0:7})
%global commits     719
%global snapdate    20260213
%global tag         4.0.0

Name:               matugen
Version:            %{tag}^%{commits}.%{shortcommit}
Release:            0%{?dist}
Summary:            A cross-platform material you and base16 color generation tool

License:            GPL-2.0
URL:                https://github.com/InioX/matugen
Source0:            %{url}/archive/%{commit}/matugen-%{shortcommit}.tar.gz

BuildRequires:  rust-packaging
BuildRequires:  cargo
BuildRequires:  gcc

%description
Flexible toolkit for making desktop shells with QtQuick, targeting
Wayland and X11.

%prep
%autosetup -n matugen-%{commit} -p1

%build
cargo build --release

%install
install -Dm0755 target/release/matugen %{buildroot}%{_bindir}/matugen

%files
%license LICENSE
%doc README.md
%{_bindir}/matugen

%changelog
%autochangelog
