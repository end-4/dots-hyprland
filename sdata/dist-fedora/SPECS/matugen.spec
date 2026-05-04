%global commit      4112d352914742ba69f6380fd07984adba02d376
%global shortcommit %(c=%{commit}; echo ${c:0:7})
%global snapdate    20260322
%global tag         4.1.0

Name:               matugen
Version:            %{tag}.%{shortcommit}
Release:            0%{?dist}
Summary:            A cross-platform material you and base16 color generation tool

License:            GPL-2.0
URL:                https://github.com/InioX/matugen
Source0:            %{url}/archive/%{commit}/matugen-%{shortcommit}.tar.gz

BuildRequires:  rust-packaging
BuildRequires:  cargo
BuildRequires:  gcc

%description
A cross-platform material you and base16 color generation tool

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
