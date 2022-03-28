target_sources(lunasvg 
PRIVATE
    "${CMAKE_CURRENT_LIST_DIR}/plutovg.c"
    "${CMAKE_CURRENT_LIST_DIR}/plutovg-paint.c"
    "${CMAKE_CURRENT_LIST_DIR}/plutovg-geometry.c"
    "${CMAKE_CURRENT_LIST_DIR}/plutovg-blend.c"
    "${CMAKE_CURRENT_LIST_DIR}/plutovg-rle.c"
    "${CMAKE_CURRENT_LIST_DIR}/plutovg-dash.c"
)

target_include_directories(lunasvg
PRIVATE
    "${CMAKE_CURRENT_LIST_DIR}"
)

option(PLUTOVG_BGRA_PIXEL_ORDER "Use BGRA order instead of RGBA, useful for GDI/GDI+/Direct2D/Cairo." ON)
if(PLUTOVG_BGRA_PIXEL_ORDER)
    target_compile_definitions(lunasvg PUBLIC PLUTOVG_BGRA_PIXEL_ORDER=1)
endif()
