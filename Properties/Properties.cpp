#include "precomp.h"

#include <type_traits>
#include <stdio.h>
#include <cstdlib>

#if 0
// typeof() by Bill Gibson

/*
template<int N> struct typeof_class; // no def’n, only specializations
template<class T> struct WrapType { typedef T U; };

#define register_typeof2(N,T) \
    template<> struct typeof_class<N> { typedef WrapType<T>::U V; }; \
    char (*typeof_fct(const WrapType<T>::U &))[N];

#define register_typeof(T) register_typeof2(__COUNTER__+1, T)

#define typeof(x) typeof_class<sizeof(*typeof_fct(x))>::V
*/

/*
template<int N> struct typeof_class; // no def’n, only specializations

#define register_typeof2(N,T) \
    template<> struct typeof_class<N> { typedef T V; }; \
    char (*typeof_fct(const T&))[N];

#define register_typeof(T) register_typeof2(__COUNTER__+1, T)

#define typeof(x) typeof_class<sizeof(*typeof_fct(x))>::V

register_typeof(int);
register_typeof(bool);
*/

// Properties by Jason King from Code Project article
// http://www.codeproject.com/cpp/genericproperty.asp?df=100&forumid=4010&exp=0&select=197527&fr=26
#endif

// Extension supported only by MSVC and clang, not gcc.
// Curiously the declspec property approach requires both the property field AND the
// getter/setter to be public.
#define USE_DECLSPEC_PROPERTY 0

#if USE_DECLSPEC_PROPERTY

#define PROPERTY_GETTER(parentType, propertyType, propertyName, getterFunc) \
    __declspec(property(get=getterFunc)) propertyType propertyName
#define PROPERTY_SETTER(parentType, propertyType, propertyName, setterFunc) \
    __declspec(property(put=setterFunc)) propertyType propertyName
#define PROPERTY_GETTER_SETTER(parentType, propertyType, propertyName, getterFunc, setterFunc) \
    __declspec(property(get=getterFunc, put=setterFunc)) propertyType propertyName

#else // !USE_DECLSPEC_PROPERTY

// Standard C++ implementation, using the memory offset between the parent class and the
// property field to implicitly call the getter, rather than space wasting approaches like
// storing a reference to the field or an entire std::function (!).

#define PROPERTY_GET_PARENT_POINTER(parentType, propertyName)                               \
    char* thisAsBytePointer = const_cast<char*>(reinterpret_cast<char const*>(this));       \
    parentType* nullParent = nullptr;                                                       \
    std::ptrdiff_t selfOffset = reinterpret_cast<std::ptrdiff_t>(&nullParent->propertyName);\
    parentType* parent = reinterpret_cast<parentType*>(thisAsBytePointer - selfOffset);     \

#define PROPERTY_GETTER(parentType, propertyType, propertyName, getterFunc)                 \
    [[no_unique_address]][[msvc::no_unique_address]]                                        \
    struct _property_##propertyName                                                         \
    {                                                                                       \
        inline operator propertyType() const                                                \
        {                                                                                   \
            PROPERTY_GET_PARENT_POINTER(parentType, propertyName);                          \
            return parent->getterFunc();                                                    \
        }                                                                                   \
    } propertyName;                                                                         \

#define PROPERTY_SETTER(parentType, propertyType, propertyName, setterFunc)                 \
    [[no_unique_address]][[msvc::no_unique_address]]                                        \
    struct _property_##propertyName                                                         \
    {                                                                                       \
        inline propertyType& operator=(const propertyType& value)                           \
        {                                                                                   \
            PROPERTY_GET_PARENT_POINTER(parentType, propertyName);                          \
            return parent->setterFunc(value);                                               \
        }                                                                                   \
    } propertyName;                                                                         \

#define PROPERTY_GETTER_SETTER(parentType, propertyType, propertyName, getterFunc, setterFunc) \
    [[no_unique_address]][[msvc::no_unique_address]]                                        \
    struct _property_##propertyName                                                         \
    {                                                                                       \
        inline operator propertyType() const                                                \
        {                                                                                   \
            PROPERTY_GET_PARENT_POINTER(parentType, propertyName);                          \
            return parent->getterFunc();                                                    \
        }                                                                                   \
                                                                                            \
        inline propertyType& operator=(const propertyType& value)                           \
        {                                                                                   \
            PROPERTY_GET_PARENT_POINTER(parentType, propertyName);                          \
            return parent->setterFunc(value);                                               \
        }                                                                                   \
    } propertyName;                                                                         \

#endif // if USE_DECLSPEC_PROPERTY


class MeowState
{
    float volume;

public:
    // Function implementations for the properties.
    // Note IsLoud and IsLoud_() must have distinct names.
    float GetVolume() { return volume; }
    float& SetVolume(float newVolume) { return volume = newVolume; }
    bool IsLoud_() const { return volume >= 10; }
    bool IsQuiet_() const { return volume < 10; }

    // Define a direct getter/setter, plus some boolean properties based on the volume.
    //
    // Pass the: containing class type, property return type, property name, getter, setter.
    // It's unfortunate that we have to repeat so many types, but there doesn't seem to be
    // an effective way to access the return type of the getter via declval until the parent
    // class MeowState has been fully defined. There's also no way to get the current class,
    // as you can't say 'using PropertyParentType = decltype(*this)' outside a function.
    // If those were possible, you could just say PROPERTY_GETTER(IsLoud, IsLoud_).

    PROPERTY_GETTER_SETTER(MeowState, float, Volume, GetVolume, SetVolume);
    PROPERTY_GETTER(MeowState, bool, IsLoud, IsLoud_);
    PROPERTY_GETTER(MeowState, bool, IsQuiet, IsQuiet_);
};

// The properties themselves are zero-sized structs that should use no additional space.
static_assert(sizeof(MeowState) == sizeof(float));


int main(int argc, char* argv[])
{
    MeowState state;

    state.Volume = 5.0f;

    // Volume should print as quiet.
    // Unfortunately when using with printf, you must wrap the properties in the target data type.
    // Otherwise printf complains (rightly so) that you're trying to push the actual property struct
    // rather than the type, which doesn't match the string format specifier.
    printf("volume = %f, isLoud = %d, isQuiet = %d\n", float(state.Volume), bool(state.IsLoud), bool(state.IsQuiet));

    state.Volume = 42.0f;

    // Volume should now be loud.
    printf("volume = %f, isLoud = %d, isQuiet = %d\n", float(state.Volume), bool(state.IsLoud), bool(state.IsQuiet));

    return EXIT_SUCCESS;
}
