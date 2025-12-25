# Dear ImGui

This is a version of **Dear ImGui** that can be built as a **static** or **shared library** using CMake.

- Official Dear ImGui documentation: [BACKENDS.md](docs/BACKENDS.md)  
- Original project: [ocornut/imgui](https://github.com/ocornut/imgui)  

## Build

Example build using CMake and Ninja:

```bash
cmake -S . -B build -G Ninja \
    -DIMGUI_BACKEND=bgfx,sdl3 \
    -DCMAKE_BUILD_TYPE=Release \
    -DIMGUI_BUILD_SHARED=OFF \
    -DCMAKE_INSTALL_PREFIX=C:/libs/imgui

cmake --build build
```

### CMake Options

- `IMGUI_BACKEND` – Select the backend(s) to use. Currently supports `sdl3` and `bgfx`.  
  - The bgfx backend is a custom integration, adapted from:  
    - [sdl-bgfx-imgui-starter](https://github.com/pr0g/sdl-bgfx-imgui-starter)  
    - [bgfx](https://github.com/bkaradzic/bgfx)  
  - Modified to support ImGui version 1.92.5  

- `IMGUI_BUILD_SHARED` – ON to build as a **shared library**, OFF for **static library**  

### Backend Dependencies

Backends require their respective libraries:

- **BGFX**: Build manually using [bgfx.cmake](https://github.com/bkaradzic/bgfx.cmake)  
- **SDL3**: Build manually from [SDL](https://github.com/libsdl-org/SDL)  

These libraries are **not included** in this repository; build them separately as needed.  

## Example Project

A sample project using this library is available here:  
[sdl3-bgfx-imgui-examples](https://github.com/fernaerell/sdl3-bgfx-imgui-examples)
