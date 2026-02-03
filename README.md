# CommonQt for Qt6 (target: Qt 6.11)

This is a version of CommonQt adapted for Qt6.

CommonQt is a set of Common Lisp bindings for the Qt application framework.
It is based on the Smoke and SmokeQt libraries, which provide a bridge between C++ and Common Lisp.

## Building CommonQt on Windows

### Initial Setup

1. Ensure you have the following tools accessible via PATH (<https://doc.qt.io/qt-6/windows-building.html#step-2-installing-build-requirements-and-set-environment>):

    - Qt sources: target Qt 6.11
    - Ninja: 1.12.0 (recommended)
    - CMake: 3.22+
    - Python 3: 3.8+
        - html5lib
        - spdx-tools
    - Node.js: 20+
    - GNU Bison & Flex (or Win Flex-Bison port)
        - Bison >= 2.7 (recommended 3.7+)
        - Flex >= 2.5.35 (recommended 3.6.4+)
    - gnuwin32
    - GPerf
    - xmlstarlet: 1.6.1
    - Visual Studio 2022 Community Edition
        - C++ Desktop Development Kit
        - MSVC toolset 2022 (cl.exe)
        - Windows 11 SDK (10.0.17763+)

2. Make sure the directory that contains `win_bison.exe` and `win_flex.exe` has priority over gnuwin32 in the `PATH` environment variable.

3. Copy or rename `win_bison.exe` and `win_flex.exe` to `bison.exe` and `flex.exe`.

4. Add the qt-install\bin directory to the beginning of the PATH environment variable; it's where moc.exe and Qt's DLLs are installed.

### Compiling Non-Lisp Dependencies

Every project listed below should be compiled using "x64 Native Tools Command Prompt for VS 2022" cmd.
The suggested commands use Ninja as a generator. It can be replaced with VS solution files by changing the `-G` argument in CMake commands.
Ninja is preferred as it is faster.
Follow the order of the projects as some depend on others.

#### LLVM

Repo: <https://github.com/llvm/llvm-project>

Branch: release/19.x

```
mkdir build && cd build
cmake ../llvm -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL -DLLVM_ENABLE_RTTI=ON -DLLVM_ENABLE_PROJECTS=clang;lld -DLLVM_TARGETS_TO_BUILD=X86 -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_ENABLE_ASSERTIONS=ON -DCMAKE_INSTALL_PREFIX=%cd%\..\..\llvm-install -DCMAKE_CXX_STANDARD=17 -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl
ninja -j 6
ninja install
```

#### qtbase

Repo: <https://code.qt.io/cgit/qt/qtbase.git>

Branch: 6.11

```
configure -opensource -release -platform win32-msvc -nomake tests -nomake examples -- -DCMAKE_CXX_STANDARD=17 -DFEATURE_gui=ON -DFEATURE_widgets=ON -DFEATURE_dbus=OFF -DCMAKE_INSTALL_PREFIX=%QT_INSTALL_PREFIX% -GNinja
ninja -j 6
ninja install
```

#### qtshadertools

Repo: <https://code.qt.io/qt/qtshadertools.git>

Branch: 6.11

```
ninja -j 6 && ninja install
```

#### qtdeclarative

Repo: <https://code.qt.io/cgit/qt/qtdeclarative.git>

Branch: 6.11

```
ninja -j 6 && ninja install
```

#### qtwebsockets

Repo: <https://code.qt.io/cgit/qt/qtwebsockets.git>

Branch: 6.11

```
ninja -j 6 && ninja install
```

#### qtwebchannel

Repo: <https://code.qt.io/cgit/qt/qtwebchannel.git>

Branch: 6.11

```
ninja -j 6 && ninja install
```

#### qtwebengine

Repo: <https://code.qt.io/cgit/qt/qtwebengine.git>

Branch: 6.11

```
ninja -j 4 && ninja install
```

#### qtsvg

Repo: <https://code.qt.io/cgit/qt/qtsvg.git>

Branch: 6.11

```
ninja -j 6 && ninja install
```

#### smokegen

Repo: <https://github.com/commonqt/smokegen>

Branch: clang-qt6

```
mkdir build && cd build
cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=..\smokegen-install -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl -DSMOKE_QT_VERSION=6 -DQt6_DIR=..\qt-install\lib\cmake\Qt6 -DLLVM_DIR=..\llvm-install\lib\cmake\llvm ..\smokegen
ninja -j 6
ninja install
```

#### smokeqt

Repo: <https://github.com/commonqt/smokeqt>

Branch: qt6

```
mkdir build && cd build
cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=..\smokeqt-install -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL -DSMOKE_QT_VERSION=6 -DQt6_DIR=..\qt-install\lib\cmake\Qt6 -DLLVM_DIR=..\llvm-install\lib\cmake\llvm
ninja -j 6
ninja install
```

#### CommonQt

Repo: <https://github.com/commonqt/commonqt6>

Branch: master

```
mkdir build && cd build
cmake .. -G"Ninja" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="..\commonqt-install" -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL -DSMOKE_QT_VERSION=6 -DQt6_DIR="..\qt-install\lib\cmake\Qt6" -DQt_ROOT_DIR="..\qt-install" -DSMOKE_BASE="..\smokegen-install" -DSMOKE_QT="..\smokeqt-install"
ninja -j 6
ninja install​
```

#### Notes

- CMAKE_INSTALL_PREFIX and -prefix (for compiling qtbase) indicate the installation directory. Ensure that all those directories are included in the PATH environment variable.

- Compiling LLVM takes several GB of space, ensure that there is at least 30GB of free space.

- The configure step of qtbase will set the definitions for all other Qt projects.

- Every project must be compile in the same configuration: DEBUG or RELEASE.

- Qt, LLVM and SmokeGen MUST BE compiled in RELEASE!
The reason is that, on Windows, Qt6 differentiates the debug vs. release DLLs by a suffix letter, e.g., Qt6Core.dll (release) vs. Qt6Cored.dll (debug). The remaining projects, such as smokegen and smokeqt, are not capable of coping with such differences.
