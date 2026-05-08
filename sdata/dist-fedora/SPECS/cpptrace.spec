%global source_date_epoch_from_changelog 0

%global tag         1.0.4
%global commits     1054
%global commit      91b6b78e408a8b1c0b7146c9034a03156c082da2
%global shortcommit %(c=%{commit}; echo ${c:0:7})

Name:           cpptrace
Version:        1.0.4
Release:        1%{?dist}
Summary:        Simple, portable, and self-contained stacktrace library for C++11 and newer

License:        MIT
URL:            https://github.com/jeremy-rifkin/cpptrace
Source0:        %{url}/archive/%{commit}/cpptrace-%{shortcommit}.tar.gz

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  make
BuildRequires:  ninja-build
BuildRequires:  libunwind-devel

%description
C++ lightweight logging library used by Quickshell.

%prep
%autosetup -n cpptrace-%{commit} -p1

%build
mkdir -p build
cd build
cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DCPPTRACE_UNWIND_WITH_LIBUNWIND=true
cmake --build .

%install
cd build
DESTDIR=%{buildroot} cmake --install .

%files
%{_prefix}/local/include/*
%{_prefix}/local/lib64/*
%license LICENSE
%doc README.md
