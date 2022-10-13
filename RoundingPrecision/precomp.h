#pragma once

#define _USE_MATH_DEFINES

#include <stdlib.h>
#include <stdio.h>
#include <format>
#include <math.h>
#include <stdarg.h>
#include <string_view>
#include <assert.h>
#include <span>
#include <vector>
#include <array>
#include "Half.h"
#include "Int24.h"
#include "FixedNumber.h"
#include "Float16m7e8s1.h"

#if __has_include(<stdfloat>)
#include <stdfloat>
#endif

#ifndef __STDCPP_FLOAT64_T__
using float64_t = double;
#endif

#ifndef __STDCPP_FLOAT32_T__
using float32_t = float;
#endif

#ifndef __STDCPP_FLOAT16_T__
using float16_t = half_float::half;
#endif

using float16m10e5s1_t = float16_t;

using bfloat16_t = float16m7e8s1_t;

static_assert(sizeof(float32_t) == 4);
static_assert(sizeof(float64_t) == 8);
static_assert(sizeof(float16_t) == 2);
static_assert(sizeof(bfloat16_t) == 2);
