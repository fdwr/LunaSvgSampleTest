// TensorArraySpeedTest.cpp : Defines the entry point for the console application.
//

#include "precomp.h"

using uint = unsigned int;

template <typename T>
class span
{
public:
    span() = default;
    span(T* begin, T* end) : begin_(begin), end_(end) {}
    span(std::initializer_list<T> range) : begin_(range.begin()), end_(range.end()) {}
    template <typename Container> span(Container& container) : begin_(std::data(container)), end_(std::data(container) + std::size(container)) {}

    T* begin() noexcept { return begin_; }
    T* end() noexcept { return begin_; }
    T const* begin() const noexcept { return begin_; }
    T const* end() const noexcept { return begin_; }
    size_t size() const noexcept { return end_ - begin_; } // Not stupid intptr_t like gsl::span.
    T const& operator[](size_t index) const noexcept { return begin_[index]; }
    T& operator[](size_t index) noexcept { return begin_[index]; }

protected:
    T* begin_ = nullptr;
    T* end_ = nullptr;
};

uint64_t milliseconds_now()
{
    static LARGE_INTEGER s_frequency;
    static BOOL s_use_qpc = QueryPerformanceFrequency(&s_frequency);

    if (s_use_qpc)
    {
        LARGE_INTEGER now;
        QueryPerformanceCounter(&now);
        return (1000LL * now.QuadPart) / s_frequency.QuadPart;
    }
    else
    {
        return GetTickCount();
    }
}

class ElapsedTime
{
public:
    uint64_t GetDifference() { return end_ - begin_; }
    void Start() { begin_ = milliseconds_now(); }
    void Stop() { end_ = milliseconds_now(); }

protected:
    uint64_t begin_ = 0;
    uint64_t end_ = 0;
};

using PixelType = uint8_t;

void TransformTensors(
    span<uint32_t const> dimensions,
    span<PixelType const> sourcePixels,
    span<uint32_t const> sourceStrides,
    span<PixelType> targetPixels,
    span<uint32_t const> targetStrides
)
{
    assert(sourcePixels.size() == targetPixels.size());
    assert(dimensions.size() >= 2);
    assert(sourceStrides.size() >= 2);
    assert(targetStrides.size() >= 2);
    assert(sourceStrides[0] * dimensions[0] + sourceStrides[1] * dimensions[1] - 1);

    const uint height = dimensions[0];
    const uint width = dimensions[1];
    const uint sourceStrideX = sourceStrides[1];
    const uint targetStrideX = targetStrides[1];
    uint sourceOffsetY = 0;
    uint targetOffsetY = 0;

    for (uint y = height; y > 0; --y)
    {
        uint sourceOffsetX = sourceOffsetY;
        uint targetOffsetX = targetOffsetY;
        for (uint x = width; x > 0; --x)
        {
            targetPixels[targetOffsetX] = sourcePixels[sourceOffsetX];
            sourceOffsetX += sourceStrideX;
            targetOffsetX += targetStrideX;
        }
        sourceOffsetY += sourceStrides[0];
        targetOffsetY += targetStrides[0];
    }
}

int main()
{
    // Allocate 2 bitmaps.
    uint32_t const width = 1000, height = 500;
    std::vector<PixelType> sourcePixels, targetPixels;
    uint32_t const totalElements = width * height;
    sourcePixels.resize(totalElements);
    targetPixels.resize(totalElements);
    std::iota(sourcePixels.begin(), sourcePixels.end(), 0);

    uint32_t const innerIterations = 50;
    uint32_t const outerIterations = 4;
    auto f1 = [&]() {TransformTensors({ height, width }, sourcePixels, { width, 1 }, targetPixels, { 1, height }); };
    auto f2 = [&]() {TransformTensors({ width, height }, sourcePixels, { 1, width }, targetPixels, { height, 1 }); };

    ElapsedTime elapsedTime;

    for (auto i = 0; i < outerIterations; ++i)
    {
        f1();
        elapsedTime.Start();
        for (auto i = 0; i < innerIterations; ++i)
        {
            f1();
        }
        elapsedTime.Stop();
        printf("time read adjacent : %d\r\n", static_cast<uint32_t>(elapsedTime.GetDifference()));

        f2();
        elapsedTime.Start();
        for (auto i = 0; i < innerIterations; ++i)
        {
            f2();
        }
        elapsedTime.Stop();
        printf("time write adjacent: %d\r\n", static_cast<uint32_t>(elapsedTime.GetDifference()));
    }

    _getch();
    return EXIT_SUCCESS;
}
