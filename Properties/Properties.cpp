#include "precomp.h"

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

#define USE_DECLSPEC_PROPERTY 0
#if USE_DECLSPEC_PROPERTY

#define property_getter( type, propName, getFunc )     \
        __declspec( property( get=getFunc ) ) type propName
#define property_setter( type, propName, setfunc )     \
        __declspec( property( set=setfunc ) ) type propName
#define property_getset( type, propName, getFunc, setFunc )\
        __declspec( property( get=getFunc, set=setFunc ) ) type propName

#else

#pragma warning(disable: 4200)

#define property_getter( type, propName, getFunc )                      \
    struct _property_##propName                                         \
    {                                                                   \
        inline operator type() const                                    \
        {                                                               \
            char* offset = (char*) &((Self*)0)->propName;               \
            return ((Self*) ((char*)this - offset) )->getFunc();        \
        }                                                               \
    } propName;                                                         \
    friend struct _property_##propName;

#define property_setter( type, propName, setFunc )                      \
    struct _property_##propName                                         \
    {                                                                   \
        inline type operator=(const type& value) const                  \
        {                                                               \
            char* offset = (char*) &((Self*)0)->propName;               \
            return ((Self*) ((char*)this - offset) )->setFunc(value);   \
        }                                                               \
    } propName;                                                         \
    friend struct _property_##setFunc;

#define property_getset( type, propName, getFunc, setFunc )             \
    friend struct                                                       \
    {                                                                   \
        inline operator type() const                                    \
        {                                                               \
            char* offset = (char*) &((Self*)0)->propName;               \
            return ((Self*) ((char*)this - offset) )->getFunc();        \
        }                                                               \
        inline type operator=(const type & value) const                 \
        {                                                               \
            char* offset = (char*) &((Self*)0)->propName;               \
            return ((Self*) ((char*)this - offset) )->setFunc(value);   \
        }                                                               \
    } propName;                                                         \
    //friend struct _property_##propName;
#endif


#define deftype(newtype,basetype) typedef /*is backwards*/ basetype newtype;

deftype(uint, unsigned int);


struct ButtonState
{
    deftype(Self, ButtonState);

    enum
    {
        Up,
        Released,
        Down,
        Pressed,
    };

    union {
        // Encase in union, else silly standard allocates 1 byte each
        // because C++ spec says that even a zero byte structure must
        // have at least one byte, since no two vars can have same
        // offset.

        property_getter(bool, IsUp,       IsUp_);
        property_getter(bool, IsDown,     IsDown_);
        property_getter(bool, IsPressed,  IsPressed_);
        property_getter(bool, IsReleased, IsReleased_);

        int value;
    };


    inline operator uint() { return value; }
    inline Self operator=(const int newValue) { value = newValue; }

//private:
    inline bool IsUp_()       const { return value <= Released; }
    inline bool IsDown_()     const { return value >= Down; }
    inline bool IsReleased_() const { return value == Released; }
    inline bool IsPressed_()  const { return value == Pressed; }
};


int _tmain(int argc, _TCHAR* argv[])
{
    ButtonState bs;
    bs.value = 0;
    int a;
    a = bs.IsPressed;
    a = bs.IsPressed_();
    a = sizeof(ButtonState);
    //typeof(a) b = 5;
    return 0;
}
