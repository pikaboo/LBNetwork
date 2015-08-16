/*
 * Logging.h
 *
 * $Version: Logging 1.0 (1e09f90c5fec) on 2010-07-22 $
 * Author: Bill Hollings
 * Copyright (c) 2010 The Brenwill Workshop Ltd. 
 * http://www.brenwill.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * http://en.wikipedia.org/wiki/MIT_License
 *
 * Thanks to Nick Dalton for providing the underlying ideas for using variadic macros as
 * well as for outputting the code location as part of the log entry. For his ideas, see:
 *   http://iphoneincubator.com/blog/debugging/the-evolution-of-a-replacement-for-nslog
 */


/**
 * For Objective-C code, this library adds flexible, non-intrusive logging capabilities
 * that can be efficiently enabled or disabled via compile switches.
 *
 * There are four levels of logging: Trace, Info, Error and Debug, and each can be enabled
 * independently via the LOGGING_LEVEL_TRACE, LOGGING_LEVEL_INFO, LOGGING_LEVEL_ERROR and
 * LOGGING_LEVEL_DEBUG switches, respectively.
 *
 * In addition, ALL logging can be enabled or disabled via the LOGGING_ENABLED switch.
 *
 * Logging functions are implemented here via macros. Disabling logging, either entirely, or
 * at a specific level, completely removes the corresponding log invocations from the compiled
 * code, thus eliminating both the memory and CPU overhead that the logging calls would add.
 * You might choose, for example, to completely remove all logging from production release code,
 * by setting LOGGING_ENABLED off in your production builds settings. Or, as another example,
 * you might choose to include Error logging in your production builds by turning only
 * LOGGING_ENABLED and LOGGING_LEVEL_ERROR on, and turning the others off.
 *
 * To perform logging, use any of the following function calls in your code:
 *
 *		LogTrace(fmt, ...)	- recommended for detailed tracing of program flow
 *							- will print if LOGGING_LEVEL_TRACE is set on.
 *
 *		LogInfo(fmt, ...)	- recommended for general, infrequent, information messages
 *							- will print if LOGGING_LEVEL_INFO is set on.
 *
 *		LogError(fmt, ...)	- recommended for use only when there is an error to be logged
 *							- will print if LOGGING_LEVEL_ERROR is set on.
 *
 *		LogDebug(fmt, ...)	- recommended for temporary use during debugging
 *							- will print if LOGGING_LEVEL_DEBUG is set on.
 *
 * In each case, the functions follow the general NSLog/printf template, where the first argument
 * "fmt" is an NSString that optionally includes embedded Format Specifiers, and subsequent optional
 * arguments indicate data to be formatted and inserted into the string. As with NSLog, the number
 * of optional arguments must match the number of embedded Format Specifiers. For more info, see the
 * core documentation for NSLog and String Format Specifiers.
 *
 * You can choose to have each logging entry automatically include class, method and line information
 * by enabling the LOGGING_INCLUDE_CODE_LOCATION switch.
 *
 * Although you can directly edit this file to turn on or off the switches below, the preferred
 * technique is to set these switches via the compiler build setting GCC_PREPROCESSOR_DEFINITIONS
 * in your build configuration.
 */


//How to apply color formatting to your log statements:
//
// To set the foreground color:
// Insert the ESCAPE into your string, followed by "fg124,12,255;" where r=124, g=12, b=255.
//
// To set the background color:
// Insert the ESCAPE into your string, followed by "bg12,24,36;" where r=12, g=24, b=36.
//
// To reset the foreground color (to default value):
// Insert the ESCAPE into your string, followed by "fg;"
//
// To reset the background color (to default value):
// Insert the ESCAPE into your string, followed by "bg;"
//
// To reset the foreground and background color (to default values) in one operation:
// Insert the ESCAPE into your string, followed by ";"

#define XCODE_COLORS_ESCAPE @"\033["

#define XCODE_COLORS_RESET_FG  XCODE_COLORS_ESCAPE @"fg;" // Clear any foreground color
#define XCODE_COLORS_RESET_BG  XCODE_COLORS_ESCAPE @"bg;" // Clear any background color
#define XCODE_COLORS_RESET     XCODE_COLORS_ESCAPE @";"   // Clear any foreground or background color

//#define LogBlue(frmt, ...) NSLog((XCODE_COLORS_ESCAPE @"fg0,0,255;" frmt XCODE_COLORS_RESET), ##__VA_ARGS__)
//#define LogRed(frmt, ...) NSLog((XCODE_COLORS_ESCAPE @"fg255,0,0;" frmt XCODE_COLORS_RESET), ##__VA_ARGS__)

#define LOG_TRACE_COLOR XCODE_COLORS_ESCAPE @"fg235,86,70;"
#define LOG_INFO_COLOR XCODE_COLORS_ESCAPE @"fg16,179,176;"
#define LOG_DEBUG_COLOR XCODE_COLORS_ESCAPE @"fg70,89,235;"
#define LOG_ERROR_COLOR XCODE_COLORS_ESCAPE @"fg235,70,100;"

/**
 * Set this switch to  enable or disable logging capabilities.
 * This can be set either here or via the compiler build setting GCC_PREPROCESSOR_DEFINITIONS
 * in your build configuration. Using the compiler build setting is preferred for this to
 * ensure that logging is not accidentally left enabled by accident in release builds.
 */
#ifndef LOGGING_ENABLED
#	define LOGGING_ENABLED		1
#endif

/**
 * Set any or all of these switches to enable or disable logging at specific levels.
 * These can be set either here or as a compiler build settings.
 * For these settings to be effective, LOGGING_ENABLED must also be defined and non-zero.
 */
#ifndef LOGGING_LEVEL_TRACE
#	define LOGGING_LEVEL_TRACE		1
#endif
#ifndef LOGGING_LEVEL_INFO
#	define LOGGING_LEVEL_INFO		1
#endif
#ifndef LOGGING_LEVEL_ERROR
#	define LOGGING_LEVEL_ERROR		1
#endif
#ifndef LOGGING_LEVEL_DEBUG
#	define LOGGING_LEVEL_DEBUG		1
#endif
#ifndef LOGGING_COLOR
#define LOGGING_COLOR               1
#endif
/**
 * Set this switch to indicate whether or not to include class, method and line information
 * in the log entries. This can be set either here or as a compiler build setting.
 */
#ifndef LOGGING_INCLUDE_CODE_LOCATION
	#define LOGGING_INCLUDE_CODE_LOCATION	1
#endif

// *********** END OF USER SETTINGS  - Do not change anything below this line ***********


#if !(defined(LOGGING_ENABLED) && LOGGING_ENABLED)
	#undef LOGGING_LEVEL_TRACE
	#undef LOGGING_LEVEL_INFO
	#undef LOGGING_LEVEL_ERROR
	#undef LOGGING_LEVEL_DEBUG
#endif

// Logging format
#define LOG_FORMAT_NO_LOCATION(fmt, lvl, ...) NSLog((@"[%@] " fmt), lvl, ##__VA_ARGS__)
#define LOG_FORMAT_WITH_LOCATION(fmt, lvl, ...) NSLog((@"%@,%s:%d\n" fmt), lvl,__PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

//#if defined(LOGGING_INCLUDE_CODE_LOCATION)&& LOGGING_INCLUDE_CODE_LOCATION && defined(LOGGING_COLOR) && LOGGING_COLOR
//    #define LOG_FORMAT(fmt, lvl, ...) LOG_FORMAT_WITH_LOCATION((fmt XCODE_COLORS_RESET), lvl, ##__VA_ARGS__)
#if  defined(LOGGING_INCLUDE_CODE_LOCATION) && LOGGING_INCLUDE_CODE_LOCATION
	#define LOG_FORMAT(fmt, lvl, ...) LOG_FORMAT_WITH_LOCATION(fmt, lvl, ##__VA_ARGS__)
#else
	#define LOG_FORMAT(fmt, lvl, ...) LOG_FORMAT_NO_LOCATION(fmt, lvl, ##__VA_ARGS__)
#endif

// Trace logging - for detailed tracing
#if defined(LOGGING_LEVEL_TRACE) && LOGGING_LEVEL_TRACE && defined(LOGGING_COLOR) && LOGGING_COLOR
    #define LogTrace(fmt, ...) LOG_FORMAT(LOG_TRACE_COLOR fmt XCODE_COLORS_RESET,@"Trace", ##__VA_ARGS__)
#elif defined(LOGGING_LEVEL_TRACE) && LOGGING_LEVEL_TRACE
	#define LogTrace(fmt, ...) LOG_FORMAT(fmt, @"Trace", ##__VA_ARGS__)
#else
	#define LogTrace(...)
#endif

// Info logging - for general, non-performance affecting information messages
#if defined(LOGGING_LEVEL_INFO) && LOGGING_LEVEL_INFO && defined(LOGGING_COLOR) && LOGGING_COLOR
  #define LogInfo(fmt, ...) LOG_FORMAT(LOG_INFO_COLOR fmt XCODE_COLORS_RESET,@"I", ##__VA_ARGS__)
#elif defined(LOGGING_LEVEL_INFO) && LOGGING_LEVEL_INFO
	#define LogInfo(fmt, ...) LOG_FORMAT(fmt, @"I", ##__VA_ARGS__)
#else
	#define LogInfo(...)
#endif

// Error logging - only when there is an error to be logged
#if defined(LOGGING_LEVEL_ERROR) && LOGGING_LEVEL_ERROR && defined(LOGGING_COLOR) && LOGGING_COLOR
    #define LogError(fmt, ...) LOG_FORMAT(LOG_ERROR_COLOR fmt XCODE_COLORS_RESET,@"E", ##__VA_ARGS__)
#elif defined(LOGGING_LEVEL_ERROR) && LOGGING_LEVEL_ERROR
	#define LogError(fmt, ...) LOG_FORMAT(fmt, @"E", ##__VA_ARGS__)
#else
	#define LogError(...)
 #endif

// Debug logging - use only temporarily for highlighting and tracking down problems
#if defined(LOGGING_LEVEL_DEBUG) && LOGGING_LEVEL_DEBUG && defined(LOGGING_COLOR) && LOGGING_COLOR
   #define LogDebug(fmt, ...) LOG_FORMAT(LOG_DEBUG_COLOR fmt XCODE_COLORS_RESET,@"D", ##__VA_ARGS__)
#elif defined(LOGGING_LEVEL_DEBUG) && LOGGING_LEVEL_DEBUG
	#define LogDebug(fmt, ...) LOG_FORMAT(fmt, @"D", ##__VA_ARGS__)
#else
	#define LogDebug(...)
#endif

