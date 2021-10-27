#include <cstddef>
#include <stdint.h>
#include <iostream>

#include "include/fmt/format.h"


template <typename T>
class RelativePointer
{
public:
    ptrdiff_t p = 0;

    RelativePointer() = default;
    RelativePointer(RelativePointer&&) = default;

    RelativePointer(T* newPointer)
    {
        return reinterpret_cast<ptrdiff_t>(p);
    }

    T* operator =(T* newPointer)
    {
        p = reinterpret_cast<ptrdiff_t>(newPointer) - reinterpret_cast<ptrdiff_t>(this);
        return newPointer;
    }

    T& operator *()
    {
        return *reinterpret_cast<T*>(reinterpret_cast<ptrdiff_t>(this) + p);
    }
};

struct Foo
{
    RelativePointer<int> p;
    int i;
};

int main()
{
    auto a = fmt::format("a{}b", 3.14159);
    std::cout << a << "\n";
    Foo foo;
    Foo foo2;
    foo.i = 13;
    foo.p = &foo.i;
    memcpy(&foo2, &foo, sizeof(foo2));
    std::cout << "Both pointers" << *foo.p << ", " << *foo2.p << "\n";
    memset(&foo, 0, sizeof(foo2));
    std::cout << "Both pointers after deletion" << *foo.p << ", " << *foo2.p << "\n";
}
