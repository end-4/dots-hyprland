%global commit0 0e3707f6dafebb121d98b53c64364d16fefe481d
%global shortcommit0 %(c=%{commit0}; echo ${c:0:7})
%global bumpver 100

Name:           MicroTeX
Version:        0.0.1%{?bumpver:^%{bumpver}.git%{shortcommit0}}
Release:        %autorelease
Summary:        A dynamic, cross-platform, and embeddable LaTeX rendering library

License:        MIT
URL:            https://github.com/NanoMichael/MicroTeX
Source0:        %{name}-%{shortcommit0}.tar.gz

BuildRequires:  gcc-c++ cmake
BuildRequires:  pkgconfig(tinyxml2)
BuildRequires:  gtkmm3.0-devel gtksourceviewmm3-devel cairomm-devel

%description
MicroTeX is a library for rendering LaTeX mathematical formulas, supporting multiple backends
such as GTK+, Qt, and Skia. It provides both library components and demo applications for
testing LaTeX rendering.

%prep
curl -fsSL --retry 3 \
  https://codeload.github.com/NanoMichael/MicroTeX/tar.gz/%{shortcommit0} \
  -o %{_sourcedir}/%{name}-%{shortcommit0}.tar.gz
%setup -q -n %{name}-%{shortcommit0}

%build
mkdir -p build
cd build
cmake ..
make -j$(nproc)

%install
mkdir -p %{buildroot}/opt/MicroTeX
cp build/LaTeX %{buildroot}/opt/MicroTeX/
cp -r build/res %{buildroot}/opt/MicroTeX/

install -Dpm 0644 LICENSE %{buildroot}%{_licensedir}/%{name}/LICENSE
install -Dpm 0644 res/greek/LICENSE %{buildroot}%{_licensedir}/%{name}/LICENSE-greek
install -Dpm 0644 res/cyrillic/LICENSE %{buildroot}%{_licensedir}/%{name}/LICENSE-cyrillic

%files
/opt/MicroTeX/
%license %{_licensedir}/%{name}/

%changelog
%autochangelog

