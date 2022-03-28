// Scratch code that I don't want to delete, but that shouldn't go in the main code.


#if INCLUDE_PREMULTIPY_FUNCTIONAL_TEST
void PremultiplyBgraData(uint8_t* pixels, uint32_t pixelByteCount)
{
    uint8_t* data = g_bitmap.data();
    for (uint32_t i = 0; i < pixelByteCount; i += 4)
    {
        data[i + 0] = data[i + 0] * data[i + 3] / 255;
        data[i + 1] = data[i + 1] * data[i + 3] / 255;
        data[i + 2] = data[i + 2] * data[i + 3] / 255;
    }
}

void Unpremultiply1(
    lunasvg::Bitmap& bitmap,
    int ri,
    int gi,
    int bi,
    int ai,
    bool unpremultiply
)
{
    const uint32_t width = bitmap.width();
    const uint32_t height = bitmap.height();
    const uint32_t stride = bitmap.stride();
    auto rowData = bitmap.data();

    // warning C4018: '<': signed/unsigned mismatch
    for (uint32_t y = 0; y < height; ++y)
    {
        auto data = rowData;
        for (uint32_t x = 0; x < width; ++x)
        {
            auto b = data[0];
            auto g = data[1];
            auto r = data[2];
            auto a = data[3];

            if (unpremultiply && a != 0)
            {
                r = (r * 255) / a;
                g = (g * 255) / a;
                b = (b * 255) / a;
            }

            //data[ri] = r;
            //data[gi] = g;
            //data[bi] = b;
            //data[ai] = a;
            data[0] = b;
            data[1] = g;
            data[2] = r;
            data[3] = a;
            data += 4;
        }
        rowData += stride;
    }
}


void Unpremultiply2(
    lunasvg::Bitmap& bitmap,
    int ri,
    int gi,
    int bi,
    int ai,
    bool unpremultiply
)
{
    const uint32_t width = bitmap.width();
    const uint32_t height = bitmap.height();
    const uint32_t stride = bitmap.stride();
    auto rowData = bitmap.data();

    for (uint32_t y = 0; y < height; ++y)
    {
        auto data = rowData;
        for (uint32_t x = 0; x < width; ++x)
        {
            auto b = data[0];
            auto g = data[1];
            auto r = data[2];
            auto a = data[3];

            uint32_t adjustedA = a - 1;
            //if (unpremultiply && adjustedA <= 254)
            // 282ms vs 200ms
            if (unpremultiply && a != 0)
            {
                uint32_t f = (16777215 / a);
                r = (r * f) >> 16;
                g = (g * f) >> 16;
                b = (b * f) >> 16;
                //r = (r * 255) / a;
                //g = (g * 255) / a;
                //b = (b * 255) / a;
            }

            //data[ri] = r;
            //data[gi] = g;
            //data[bi] = b;
            //data[ai] = a;
            data[0] = b;
            data[1] = g;
            data[2] = r;
            data[3] = a;
            data += 4;
        }
        rowData += stride;
    }
}


void Unpremultiply3(
    lunasvg::Bitmap& bitmap,
    int ri,
    int gi,
    int bi,
    int ai,
    bool unpremultiply
)
{
    const uint32_t width = bitmap.width();
    const uint32_t height = bitmap.height();
    const uint32_t stride = bitmap.stride();
    auto rowData = bitmap.data();
    uint8_t alphaTable[256][256];

    for (uint32_t i = 0; i < 255; ++i)
    {
        alphaTable[i][0] = i;
    }
    for (uint32_t i = 0; i < 255; ++i)
    {
        for (uint32_t a = 1; a < 256; ++a)
        {
            alphaTable[i][a] = (i * 255) / a;
        }
    }

    for (uint32_t y = 0; y < height; ++y)
    {
        auto data = rowData;
        for (uint32_t x = 0; x < width; ++x)
        {
            auto b = data[0];
            auto g = data[1];
            auto r = data[2];
            auto a = data[3];

            if (unpremultiply && a != 0)
            {
                r = alphaTable[r][a];
                g = alphaTable[g][a];
                b = alphaTable[b][a];
            }

            //data[ri] = r;
            //data[gi] = g;
            //data[bi] = b;
            //data[ai] = a;
            data[0] = b;
            data[1] = g;
            data[2] = r;
            data[3] = a;
            data += 4;
        }
        rowData += stride;
    }
}
#endif


#if INCLUDE_PREMULTIPY_FUNCTIONAL_TEST // hack:::
// Premultiply pixels so that edges are antialiased.
// hack:::PremultiplyBgraData(g_bitmap.data(), g_bitmap.stride() * g_bitmap.height());

SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_HIGHEST);
LARGE_INTEGER endTime1, endTime2, endTime3;
QueryPerformanceCounter(&startTime);

for (uint32_t i = 0; i < 300; ++i)
    Unpremultiply1(g_bitmap, 2, 1, 0, 3, true);
QueryPerformanceCounter(&endTime1);

for (uint32_t i = 0; i < 300; ++i)
    Unpremultiply2(g_bitmap, 2, 1, 0, 3, true);
QueryPerformanceCounter(&endTime2);

for (uint32_t i = 0; i < 300; ++i)
    Unpremultiply3(g_bitmap, 2, 1, 0, 3, true);
QueryPerformanceCounter(&endTime3);
SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_NORMAL);

auto GetDuration = [=](LARGE_INTEGER startTime, LARGE_INTEGER endTime) -> double
{
    return double(endTime.QuadPart - startTime.QuadPart) * 1000 / double(cpuFrequency.QuadPart);
};
double durationMs1 = GetDuration(startTime, endTime1);
double durationMs2 = GetDuration(endTime1, endTime2);
double durationMs3 = GetDuration(endTime2, endTime3);
_snwprintf_s(windowTitle, sizeof(windowTitle), L"%s (%1.6fms, %1.6fms, %1.6fms)", g_applicationTitle, durationMs1, durationMs2, durationMs3);
SetWindowText(hwnd, windowTitle);
#endif
