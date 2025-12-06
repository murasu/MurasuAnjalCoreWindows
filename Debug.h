#pragma once
#include <Windows.h>
#include <stdio.h>
#include <stdarg.h>

#define logTag L"MurasuAnjal"

class Debug {
public:
    // Wide string output without tag
    static void OutputW(const WCHAR* szFormat, ...)
    {
        WCHAR szBuff[2048];
        va_list arg;
        va_start(arg, szFormat);
        vswprintf_s(szBuff, _countof(szBuff), szFormat, arg);
        va_end(arg);
        OutputDebugStringW(szBuff);
    }

    // Wide string output with tag
    static void OutputW(const WCHAR* tag, const WCHAR* szFormat, ...)
    {
        WCHAR szBuff[2048];
        WCHAR szTaggedBuff[2560];
        va_list arg;
        va_start(arg, szFormat);
        vswprintf_s(szBuff, _countof(szBuff), szFormat, arg);
        va_end(arg);

        if (tag && wcslen(tag) > 0) {
            swprintf_s(szTaggedBuff, _countof(szTaggedBuff), L"[%s] %s\n", tag, szBuff);
            OutputDebugStringW(szTaggedBuff);
        }
        else {
            swprintf_s(szTaggedBuff, _countof(szTaggedBuff), L"%s\n", szBuff);
            OutputDebugStringW(szTaggedBuff);
        }
    }

    // ANSI string output without tag
    static void OutputA(const char* szFormat, ...)
    {
        char szBuff[2048];
        va_list arg;
        va_start(arg, szFormat);
        vsprintf_s(szBuff, _countof(szBuff), szFormat, arg);
        va_end(arg);
        OutputDebugStringA(szBuff);
    }

    // ANSI string output with tag
    static void OutputA(const char* tag, const char* szFormat, ...)
    {
        char szBuff[2048];
        char szTaggedBuff[2560];
        va_list arg;
        va_start(arg, szFormat);
        vsprintf_s(szBuff, _countof(szBuff), szFormat, arg);
        va_end(arg);

        if (tag && strlen(tag) > 0) {
            sprintf_s(szTaggedBuff, _countof(szTaggedBuff), "[%s] %s\n", tag, szBuff);
            OutputDebugStringA(szTaggedBuff);
        }
        else {
            sprintf_s(szTaggedBuff, _countof(szTaggedBuff), "%s\n", szBuff);
            OutputDebugStringA(szTaggedBuff);
        }
    }
};

// Convenience macros
#define DebugOut Debug::OutputW
#define DebugOutA Debug::OutputA