cmake -S . -B build -G Ninja \
    -DIMGUI_BACKEND=bgfx,sdl3 \
    -DCMAKE_BUILD_TYPE=Release \
    -DIMGUI_BUILD_SHARED=OFF \
    -DCMAKE_INSTALL_PREFIX=C:/libs/imgui

cmake --build build