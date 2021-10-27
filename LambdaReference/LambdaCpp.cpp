// ReverseString.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include <iostream>
#include <stdio.h>
#include <functional>
#include <utility>
#include <type_traits>

// Extracts a return type and argument types from a given function signature
// (sadly decltype, std::result_of, std::invoke_result do not work for this purpose).
//
//      using ReturnType = FunctionSignatureExtractor<void(int, double)>::ReturnType;
//      using ArgumentType0 = std::tuple_element_t<0, FunctionSignatureExtractor<void(int, double)>::ArgumentType>;
//      using ArgumentType1 = std::tuple_element_t<1, FunctionSignatureExtractor<void(int, double)>::ArgumentType>;

template<typename ReturnTypeT>
struct FunctionSignatureExtractor;

template<typename ReturnTypeT, typename... Args>
struct FunctionSignatureExtractor<ReturnTypeT(Args...)>
{
    using ReturnType = ReturnTypeT;
    using ArgumentTypeList = std::tuple<Args...>;
    using FunctionType = ReturnTypeT(Args...);

    // Prepend a single argument to the beginning - useful for thunks.
    template <typename T>
    using PrependArgument = ReturnTypeT(T, Args...);
};

template <typename T> T identity(T); // std::identity not implemented until C++20 :/.

template <typename FunctionType>
struct LambdaReference
{
    using Self = typename LambdaReference<FunctionType>;

    LambdaReference() = default;
    LambdaReference(Self& l) = default;
    LambdaReference(Self&& l) = default;

    using SignatureExtractor = typename FunctionSignatureExtractor<FunctionType>;
    using ReturnType = typename SignatureExtractor::ReturnType;
    using ArgumentTypeList = typename SignatureExtractor::ArgumentTypeList;
    using ThunkFunctionType = typename SignatureExtractor::template PrependArgument<Self&>;
    // using FirstArgument = std::tuple_element_t<0, typename SignatureExtractor::ArgumentTypeList>;

    template <typename... Args>
    static ReturnType BadFunctionalCall(Self& self, Args... args)
    {
        throw std::bad_function_call();
    }

    template <typename... Args>
    inline ReturnType Call(Args... args)
    {
        return thunk(*this, args...);
        // Wish there was a way to force 'explicit' on parameters so no type casting is done.
        // That way the error (if you pass the wrong variable type) occurs at the call site
        // rather than inside here, which is confusing and inhibits tail call efficiency.
        // TODO: Use std::forward or not?
    }

    template <typename LambdaType, typename... Args>
    static inline ReturnType CallThunk(Self& self, Args... args)
    {
        // Since the lambda type is known, we can just call in directly,
        // rather than needing another function pointer:
        //
        //      decltype(&LambdaType::operator()) lambdaPointer;
        //
        // Note any decent compiler with optimizations enabled should turn this into a tail call
        // (small stack fix-up to repoint this pointer and a jump).
        // https://godbolt.org/#z:OYLghAFBqd5QCxAYwPYBMCmBRdBLAF1QCcAaPECAKxAEZSAbAQwDtRkBSAJgCFufSAZ1QBXYskwgA5NwDMeFsgYisAag6yAwskEF8qDdg4AGAIInTCgqoBGTYhCulVVgJQa%2BZi1dUAzVKiOLNYszj5MyMiu6gDsnqaqiarEmARiLKoQGRoAIrmqxtEaAGKqEciqILb2WaoAtKr0ZZHqvKpc7rLxHDF5XmY%2Bdg4%2BoS7BzVGx8UnJqemZ2bJ5SwVFsqXllX4BtQ1Nm/yNnd29Uq6M0gCsUqQs0sY3qNKa/IfCYhKtsrQ3BPdn5wA1iAuMYLlIACw3O5SB6kJ5SG6CEBgv6ws6kOCwJBoAC2AAc8AxMGQKBA8YTicQQMAABz0XxEggk5EQGz/Ug2BT2ACe0h%2BpDxuMwwQA8iwGHz0aQsLjWMBiRz8ClkAQ8AA3TDI6WYAAemGQImZ/JuVkwDA5BGIeFx/3OzDYKFevEYeBsyMg51Q%2BLVqBY2rqotkSNE4kktHtV2hHIRutpADY6vGIapgC1aQA6WiZXCEEhfJqaVAEokkgvRF68fi/O3nBCYJhYakQIEgsEWyHR6UIpEo0hoh7nLGIFDFykk8iUCml6lKeXx4xgxkMZnEVns6Vcli8k2C4vCsUSqVw2XyxXS5UGtWa7VwvUGo2SKQCs0duFWm12xjyp1Vl0MN0PRbeEfTwP0AyDEMPnDSMpGuW4Y2kONE2TVQ5zYVR4wzYxsJzfAiGIAtnCLEsqS%2BDpVErPheBrdFXFbUFwShBDu2kXtUS/YcIBxMcZ0ncleKpEA8EiWhaVIZdV3XDktx3Z8biFEUCHFSUlUwOU2HPE88BVa8tQ5e9DWNeTyGCc1LWtW06O/R1OD/AQAPdeAvVA8DpEDYMhFDCQ6Fg%2BCYThWMEyTFMRIqMTsNwiBcwIojKMEss5FkCtnR4WjBwY9tpGYgLHjYoQ%2BwHDEuJ40iJzJachKUWgAE4AH1kwkpkWUoDc4Vk4gpQFRTD1Ui91LPJ9tN0jV9J1fUjKfF8zLfX5LK/B12FS10nM9EDfX9EAAHpRS4LzoN88F/MQqRkJC1QAFkAGUADVNEaGr2mMWgYlUAAlAAVAB1PC80IuRCwS/6uFkCEUvs9KAVIYFGI7HKTvY/ta3BLgu0C/Kivo0hNTXMC7ghIA

        auto& lambda = *reinterpret_cast<LambdaType*>(self.functionData);
        return lambda(args...);
    }

    template <typename... Args>
    static inline ReturnType FreeFunctionCallThunk(Self& self, Args... args)
    {
        //GenericLambdaPointer<LambdaType> g;
        //g.lambdaPointerVoid = self.originalFunction;
        //return g.lambdaPointer(x);
        // Note any decent compiler with optimizations enabled should turn this into a tail call
        // (small stack fix-up to repoint this pointer and a jump).
        // https://godbolt.org/#z:OYLghAFBqd5QCxAYwPYBMCmBRdBLAF1QCcAaPECAKxAEZSAbAQwDtRkBSAJgCFufSAZ1QBXYskwgA5NwDMeFsgYisAag6yAwskEF8qDdg4AGAIInTCgqoBGTYhCulVVgJQa%2BZi1dUAzVKiOLNYszj5MyMiu6gDsnqaqiarEmARiLKoQGRoAIrmqxtEaAGKqEciqILb2WaoAtKr0ZZHqvKpc7rLxHDF5XmY%2Bdg4%2BoS7BzVGx8UnJqemZ2bJ5SwVFsqXllX4BtQ1Nm/yNnd29Uq6M0gCsUqQs0sY3qNKa/IfCYhKtsrQ3BPdn5wA1iAuMYLlIACw3O5SB6kJ5SG6CEBgv6ws6kOCwJBoAC2AAc8AxMGQKBA8YTicQQMAABz0XxEggk5EQGz/Ug2BT2ACe0h%2BpDxuMwwQA8iwGHz0aQsLjWMBiRz8ClkAQ8AA3TDI6WYAAemGQImZ/JuVkwDA5BGIeFx/3OzDYKFevEYeBsyMg51Q%2BLVqBY2rqotkSNE4kktHtV2hHIRutpADY6vGIapgC1aQA6WiZXCEEhfJqaVAEokkgvRF68fi/O3nBCYJhYakQIEgsEWyHR6UIpEo0hoh7nLGIFDFykk8iUCml6lKeXx4xgxkMZnEVns6Vcli8k2C4vCsUSqVw2XyxXS5UGtWa7VwvUGo2SKQCs0duFWm12xjyp1Vl0MN0PRbeEfTwP0AyDEMPnDSMpGuW4Y2kONE2TVQ5zYVR4wzYxsJzfAiGIAtnCLEsqS%2BDpVErPheBrdFXFbUFwShBDu2kXtUS/YcIBxMcZ0ncleKpEA8EiWhaVIZdV3XDktx3Z8biFEUCHFSUlUwOU2HPE88BVa8tQ5e9DWNeTyGCc1LWtW06O/R1OD/AQAPdeAvVA8DpEDYMhFDCQ6Fg%2BCYThWMEyTFMRIqMTsNwiBcwIojKMEss5FkCtnR4WjBwY9tpGYgLHjYoQ%2BwHDEuJ40iJzJachKUWgAE4AH1kwkpkWUoDc4Vk4gpQFRTD1Ui91LPJ9tN0jV9J1fUjKfF8zLfX5LK/B12FS10nM9EDfX9EAAHpRS4LzoN88F/MQqRkJC1QAFkAGUADVNEaGr2mMWgYlUAAlAAVAB1PC80IuRCwS/6uFkCEUvs9KAVIYFGI7HKTvY/ta3BLgu0C/Kivo0hNTXMC7ghIA
        auto* function = reinterpret_cast<FunctionType*>(self.functionData);
        return function(args...);
    }

    void Set(FunctionType function)
    {
        functionData = function;
        thunk = &FreeFunctionCallThunk<>;
    }

    using SignatureExtractor2 = typename FunctionSignatureExtractor<FunctionType>;

    template <typename LambdaType>
    void Set(LambdaType const& lambdaType)
    {
        // Tried to work around compiler bug:
        // error C3556: 'main::Cat::operator ()': incorrect argument to 'decltype'
        // But even that failed if more than one operator() exists in the class.
        // https://stackoverflow.com/questions/12404362/incorrect-argument-to-decltype
        // http://softnfuzzy.blogspot.com/2011/12/decltype-on-visual-studio.html
        // using LambdaFunctionSignture = decltype(&LambdaType::operator());
        // using LambdaSignatureExtractor = FunctionSignatureExtractor<FunctionType>;
        // using LambdaReturnType = typename LambdaSignatureExtractor::ReturnType;
        // using LambdaArgumentTypeList = typename LambdaSignatureExtractor::ArgumentTypeList;

        // is_invocable is pretty useless here for determining compatible cases.
        // If is_invocable could just take a tuple type list, then it would actually be valuable.
        // static_assert(std::is_invocable<FunctionType, Args...>::value, "Set() expects lambda function to have compatible callable type.");

        thunk = &CallThunk<LambdaType>;
        functionData = const_cast<LambdaType*>(&lambdaType);
    }

public:
    void* functionData = nullptr;
    ThunkFunctionType* thunk = &BadFunctionalCall;
};

float FreeFunction(int x)
{
    return float(x + 2);
}

int main()
{
    int x = 2, y = 3, z = -3;
    auto lamb0 = [](int a)  {return float(a + 2); };
    auto lamb1 = [&](int a) {return float(a + x); };
    auto lamb2 = [=](int a) {return float(a + x); };
    auto lamb3 = [&](int a) {return float(a + x + y + z); };
    auto lamb4 = [=](int a) {return float(a + x + y + z); };
    auto lamb5 = [=](float a, int b, bool c) {return int(a + b + c); };
    auto lamb6 = +[](int a)  {return float(a + 2); };

    /* The syntax we wish we could have enjoyed.
    auto lamb0 = @(int a) {return a + 1; };
    auto lamb0 = @(a) => (a + 1);
    auto lamb0 = (a) => a + 1;
    auto lamb1 = @{&}(int a) {return a + x; };
    auto lamb2 = @{=}(int a) {return a + x; };
    auto lamb3 = @{&}(int a) {return a + x + y + z; };
    auto lamb4 = @{=}(int a) {return a + x + y + z; };
    */

    std::function<float(int)> func(lamb0);

    LambdaReference<float(int)> lambdaReference;

    // lambdaReference.Set(lamb5); // As expected, causes error: Set() expects lambda function to have compatible callable type.

    //printf("free function %f", lambdaReference.function(1));
    //
    //lambdaReference.function = lamb0;
    //lambdaReference.data = &lamb0;
    //printf("lambda stateless %f", lambdaReference.function(1));

    func = FreeFunction;
    lambdaReference.Set(&FreeFunction);
    printf("free function %f\n", lambdaReference.Call(1));

    static_assert(std::is_invocable<float(int), int>::value, "Set() expects lambda function to have compatible callable type.");

    lambdaReference.Set(lamb0);
    printf("lambda stateless %f\n", lambdaReference.Call(1));
    lambdaReference.Set(lamb3);
    printf("lambda stateful %f\n", lambdaReference.Call(1));

    class Cat
    {
    public:
        int x = 2;

        float operator ()(int a)
        {
            return float(a + x);
        }

        //float operator ()(int a) const
        //{
        //    return float(a + x + 1);
        //}
    };

    Cat cat;
    const Cat constCat;

    class Dog
    {
    public:
        int x = 2;

        float Bark(int a)
        {
            return float(a + x);
        }
    };

    Dog dog;

    lambdaReference.Set(cat);
    printf("mutable class functor %f\n", lambdaReference.Call(1));

    lambdaReference.Set(constCat);
    printf("const class functor %f\n", lambdaReference.Call(1));

    lambdaReference.Set([&](int x) {return dog.Bark(x); });
    printf("inline stateful lambda calling class method %f\n", lambdaReference.Call(1));
    using namespace std::placeholders;
    auto boundObject = std::bind(&Dog::Bark, &dog, _1);
    lambdaReference.Set(boundObject);
    printf("std::bind to class method %f\n", lambdaReference.Call(1));

    lambdaReference.Set(lamb6);
    printf("lambda +[] %f\n", lambdaReference.Call(1));

    LambdaReference<int(float,int,bool)> lambdaReference2;
    lambdaReference2.Set(lamb5);
    printf("lambda stateful multiple parameters %d\n", lambdaReference2.Call(1.0f, 1, true));

    // https://stackoverflow.com/questions/28746744/passing-capturing-lambda-as-function-pointer#:~:text=Lambda%20expressions%2C%20even%20captured%20ones%2C%20can%20be%20handled,of%20an%20%22function%22%20class%20in%20style%20of%20std%3A%3Afunction.
    float(decltype(lamb3)::*lamb3Ptr)(int)const = &decltype(lamb3)::operator();
    (lamb3.*lamb3Ptr)(1);

    // https://stackoverflow.com/questions/18889028/a-positive-lambda-what-sorcery-is-this
    // https://stackoverflow.com/questions/17822131/resolving-ambiguous-overload-on-function-pointer-and-stdfunction-for-a-lambda
    // http://www.vishalchovatiya.com/learn-lambda-function-in-cpp-with-example/#How_Does_Lambda_Functions_Works_Internally
    auto test = +[]{}; // Note the unary operator + before the lambda
    test = []{};
    [&] {++x; }; // Just declared - not run.
    [&] {++x; }(); // Actually run too.

    // std::is_member_function_pointer - https://en.cppreference.com/w/cpp/types/is_member_function_pointer
    // std::result_of<S(char, int&)>::type - https://en.cppreference.com/w/cpp/types/result_of
    // std::bad_function_call - https://en.cppreference.com/w/cpp/utility/functional/bad_function_call

    printf(
        "lambda0=%d bytes\n"
        "lambda1=%d bytes\n"
        "lambda2=%d bytes\n"
        "lambda3=%d bytes\n"
        "lambda4=%d bytes\n"
        "lambda3Ptr=%d bytes\n"
        "std::function=%d bytes\n"
        "(lamb3.*lamb3Ptr)(4) = %f\n"
        "x = %d\n"
        ,
        int(sizeof(lamb0)),
        int(sizeof(lamb1)),
        int(sizeof(lamb2)),
        int(sizeof(lamb3)),
        int(sizeof(lamb4)),
        int(sizeof(lamb3Ptr)),
        int(sizeof(func)),
        (lamb3.*lamb3Ptr)(4),
        x
    );
}
