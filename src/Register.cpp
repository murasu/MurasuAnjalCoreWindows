// Register.cpp
// COM registration for MurasuAnjalCore TSF IME

#include "../include/MurasuAnjalCore.h"
#include "../include/Debug.h"
#include <olectl.h>
#include <strsafe.h>
#include <msctf.h>

// Registry helper functions
static BOOL RegisterProfiles();
static void UnregisterProfiles();
static BOOL RegisterCategories();
static void UnregisterCategories();
static BOOL RegisterServer();
static void UnregisterServer();

//
// DllRegisterServer
//
STDAPI DllRegisterServer(void)
{
    DebugOut(logTag, L"DllRegisterServer called");

    HRESULT hrCo = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
    bool coInitSucceeded = (hrCo == S_OK || hrCo == S_FALSE);

    if (!RegisterServer())
    {
        if (coInitSucceeded) CoUninitialize();
        return E_FAIL;
    }

    if (!RegisterProfiles())
    {
        DllUnregisterServer();
        if (coInitSucceeded) CoUninitialize();
        return E_FAIL;
    }

    if (!RegisterCategories())
    {
        DllUnregisterServer();
        if (coInitSucceeded) CoUninitialize();
        return E_FAIL;
    }

    if (coInitSucceeded)
        CoUninitialize();

    return S_OK;
} 

//
// DllUnregisterServer
//
STDAPI DllUnregisterServer(void)
{
    UnregisterCategories();
    UnregisterProfiles();
    UnregisterServer();

    return S_OK;
}

static BOOL RegisterServer()
{
    DebugOut(logTag, L"RegisterServer called");

    HKEY hKey = NULL;
    HKEY hSubKey = NULL;
    LONG result;
    WCHAR achIMEKey[512];
    WCHAR achFileName[MAX_PATH];
    DWORD dw;

    if (!GetModuleFileNameW(g_hInst, achFileName, ARRAYSIZE(achFileName)))
        return FALSE;

    StringCchPrintfW(achIMEKey, ARRAYSIZE(achIMEKey),
        L"SOFTWARE\\Classes\\CLSID\\{%08lX-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X}",
        c_clsidTextService.Data1,
        c_clsidTextService.Data2,
        c_clsidTextService.Data3,
        c_clsidTextService.Data4[0],
        c_clsidTextService.Data4[1],
        c_clsidTextService.Data4[2],
        c_clsidTextService.Data4[3],
        c_clsidTextService.Data4[4],
        c_clsidTextService.Data4[5],
        c_clsidTextService.Data4[6],
        c_clsidTextService.Data4[7]);

    // ✅ CRITICAL FIX: Use HKEY_LOCAL_MACHINE instead of HKEY_CLASSES_ROOT
    result = RegCreateKeyExW(HKEY_LOCAL_MACHINE, achIMEKey, 0, NULL,
        REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &hKey, &dw);

    DebugOut(logTag, L"RegCreateKeyEx result: 0x%08X for path: %s", result, achIMEKey);

    if (result != ERROR_SUCCESS)
        return FALSE;

    // Set description
    result = RegSetValueExW(hKey, NULL, 0, REG_SZ,
        (BYTE*)TEXTSERVICE_DESC,
        (lstrlenW(TEXTSERVICE_DESC) + 1) * sizeof(WCHAR));

    DebugOut(logTag, L"Set description result: 0x%08X", result);

    // InprocServer32
    result = RegCreateKeyExW(hKey, L"InprocServer32", 0, NULL,
        REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &hSubKey, &dw);

    DebugOut(logTag, L"Create InprocServer32 key result: 0x%08X", result);

    if (result == ERROR_SUCCESS)
    {
        result = RegSetValueExW(hSubKey, NULL, 0, REG_SZ,
            (BYTE*)achFileName,
            (lstrlenW(achFileName) + 1) * sizeof(WCHAR));

        DebugOut(logTag, L"Set DLL path result: 0x%08X, path: %s", result, achFileName);

        result = RegSetValueExW(hSubKey, L"ThreadingModel", 0, REG_SZ,
            (BYTE*)TEXTSERVICE_MODEL,
            (lstrlenW(TEXTSERVICE_MODEL) + 1) * sizeof(WCHAR));

        DebugOut(logTag, L"Set ThreadingModel result: 0x%08X", result);

        RegCloseKey(hSubKey);
    }

    RegCloseKey(hKey);

    return TRUE;
}

static void UnregisterServer()
{
    WCHAR achIMEKey[512];

    StringCchPrintfW(achIMEKey, ARRAYSIZE(achIMEKey),
        L"CLSID\\{%08lX-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X}",
        c_clsidTextService.Data1,
        c_clsidTextService.Data2,
        c_clsidTextService.Data3,
        c_clsidTextService.Data4[0],
        c_clsidTextService.Data4[1],
        c_clsidTextService.Data4[2],
        c_clsidTextService.Data4[3],
        c_clsidTextService.Data4[4],
        c_clsidTextService.Data4[5],
        c_clsidTextService.Data4[6],
        c_clsidTextService.Data4[7]);

    RegDeleteTreeW(HKEY_CLASSES_ROOT, achIMEKey);
}

BOOL RegisterProfiles()
{
    DebugOut(logTag, L"RegisterProfiles START");

    ITfInputProcessorProfiles* pInputProcessorProfiles;
    WCHAR achIconFile[MAX_PATH];
    DWORD cchIconFile;
    HRESULT hr;

    hr = CoCreateInstance(CLSID_TF_InputProcessorProfiles, NULL, CLSCTX_INPROC_SERVER,
        IID_ITfInputProcessorProfiles, (void**)&pInputProcessorProfiles);

    DebugOut(logTag, L"CoCreateInstance result: 0x%08X", hr);

    if (hr != S_OK)
        goto Exit;

    hr = pInputProcessorProfiles->Register(c_clsidTextService);
    DebugOut(logTag, L"Register result: 0x%08X", hr);

    if (hr != S_OK)
        goto Exit;

    cchIconFile = GetModuleFileNameW(g_hInst, achIconFile, ARRAYSIZE(achIconFile));
    DebugOut(logTag, L"DLL path: %s", achIconFile);

    hr = pInputProcessorProfiles->AddLanguageProfile(
        c_clsidTextService,
        c_langid,
        c_guidProfile,
        TEXTSERVICE_DESC,
        (ULONG)lstrlenW(TEXTSERVICE_DESC),
        achIconFile,
        cchIconFile,
        0);

    DebugOut(logTag, L"AddLanguageProfile result: 0x%08X", hr);

    if (hr != S_OK)
        goto Exit;

    // ✅ Set UWP compatibility flag using ProfileMgr
    ITfInputProcessorProfileMgr* pProfileMgr = NULL;
    hr = pInputProcessorProfiles->QueryInterface(IID_ITfInputProcessorProfileMgr, (void**)&pProfileMgr);

    if (SUCCEEDED(hr) && pProfileMgr)
    {
        TF_INPUTPROCESSORPROFILE profile;
        ZeroMemory(&profile, sizeof(profile));

        profile.dwProfileType = TF_PROFILETYPE_INPUTPROCESSOR;
        profile.langid = c_langid;
        profile.clsid = c_clsidTextService;
        profile.guidProfile = c_guidProfile;
        profile.catid = GUID_TFCAT_TIP_KEYBOARD;
        profile.hklSubstitute = NULL;
        profile.dwCaps = TF_IPP_CAPS_IMMERSIVESUPPORT | TF_IPP_CAPS_SECUREMODESUPPORT;
        profile.hkl = NULL;
        profile.dwFlags = TF_IPP_FLAG_ENABLED;

        hr = pProfileMgr->RegisterProfile(
            c_clsidTextService,
            c_langid,
            c_guidProfile,
            TEXTSERVICE_DESC,
            (ULONG)lstrlenW(TEXTSERVICE_DESC),
            achIconFile,
            cchIconFile,
            0,  // uIconIndex
            NULL,  // hklSubstitute
            0,  // dwPreferredLayout
            TRUE,  // bEnabledByDefault
            profile.dwCaps  // ⭐ This is the critical parameter
        );

        DebugOut(logTag, L"RegisterProfile with IMMERSIVESUPPORT: 0x%08X", hr);

        pProfileMgr->Release();
    }
    // ✅ END OF UWP compatibility flag
    
    // Manually add the CLSID value to the profile
    // (This is normally done automatically by ITfInputProcessorProfileMgr)
    WCHAR szProfileKey[512];
    swprintf_s(szProfileKey,
        L"SOFTWARE\\Microsoft\\CTF\\TIP\\{F7123523-AA20-43CB-8BE3-8AA74E8584F9}\\LanguageProfile\\0x00000449\\{B243DC17-B1C8-496A-B00B-5EB8C3EE4B6F}");

    HKEY hKey;
    if (RegOpenKeyExW(HKEY_LOCAL_MACHINE, szProfileKey, 0, KEY_SET_VALUE, &hKey) == ERROR_SUCCESS)
    {
        // Add CLSID value
        RegSetValueExW(hKey, L"CLSID", 0, REG_SZ,
            (BYTE*)L"{F7123523-AA20-43CB-8BE3-8AA74E8584F9}",
            sizeof(L"{F7123523-AA20-43CB-8BE3-8AA74E8584F9}"));

        // ✅ CRITICAL FIX: Add Enable flag at profile level
        DWORD dwEnable = 1;
        RegSetValueExW(hKey, L"Enable", 0, REG_DWORD,
            (BYTE*)&dwEnable, sizeof(DWORD));

        RegCloseKey(hKey);
    }

    // Enable the profile
    hr = pInputProcessorProfiles->EnableLanguageProfile(
        c_clsidTextService,
        c_langid,
        c_guidProfile,
        TRUE);

    DebugOut(logTag, L"EnableLanguageProfile result: 0x%08X", hr);

Exit:
    if (pInputProcessorProfiles)
        pInputProcessorProfiles->Release();

    DebugOut(logTag, L"RegisterProfiles END - Final result: 0x%08X", hr);

    return (hr == S_OK);
}

static void UnregisterProfiles()
{
    ITfInputProcessorProfiles* pInputProcessorProfiles = NULL;
    HRESULT hr;

    hr = CoCreateInstance(CLSID_TF_InputProcessorProfiles, NULL, CLSCTX_INPROC_SERVER,
        IID_ITfInputProcessorProfiles, (void**)&pInputProcessorProfiles);

    if (SUCCEEDED(hr))
    {
        pInputProcessorProfiles->Unregister(c_clsidTextService);
        pInputProcessorProfiles->Release();
    }
}

static BOOL RegisterCategories()
{
    DebugOut(logTag, L"RegisterCategories START");

    ITfCategoryMgr* pCategoryMgr = NULL;
    HRESULT hr;
    BOOL result = FALSE;

    hr = CoCreateInstance(CLSID_TF_CategoryMgr, NULL, CLSCTX_INPROC_SERVER,
        IID_ITfCategoryMgr, (void**)&pCategoryMgr);

    DebugOut(logTag, L"CoCreateInstance(CategoryMgr) result: 0x%08X", hr);

    if (FAILED(hr))
        return FALSE;

    // ✅ CRITICAL FIX #1: Register as KEYBOARD input method
    // This is THE most important category - without it, ctfmon.exe won't load your IME
    hr = pCategoryMgr->RegisterCategory(c_clsidTextService,
        GUID_TFCAT_TIP_KEYBOARD,
        c_clsidTextService);

    DebugOut(logTag, L"RegisterCategory(GUID_TFCAT_TIP_KEYBOARD) result: 0x%08X", hr);

    if (FAILED(hr))
    {
        pCategoryMgr->Release();
        return FALSE;
    }

    // ✅ CRITICAL FIX #2: Register for Windows Store app support
    // Modern IMEs should support immersive (Metro/UWP) apps
    hr = pCategoryMgr->RegisterCategory(c_clsidTextService,
        GUID_TFCAT_TIPCAP_IMMERSIVESUPPORT,
        c_clsidTextService);

    DebugOut(logTag, L"RegisterCategory(GUID_TFCAT_TIPCAP_IMMERSIVESUPPORT) result: 0x%08X", hr);

    // ✅ Optional: Display attribute provider (you already had this)
    hr = pCategoryMgr->RegisterCategory(c_clsidTextService,
        GUID_TFCAT_DISPLAYATTRIBUTEPROVIDER,
        c_clsidTextService);

    DebugOut(logTag, L"RegisterCategory(GUID_TFCAT_DISPLAYATTRIBUTEPROVIDER) result: 0x%08X", hr);


    hr = pCategoryMgr->RegisterCategory(c_clsidTextService,
        GUID_TFCAT_TIPCAP_UIELEMENTENABLED,
        c_clsidTextService);
    DebugOut(logTag, L"RegisterCategory(GUID_TFCAT_TIPCAP_UIELEMENTENABLED) result: 0x%08X", hr);

    // Add these 4 to Register.cpp:
    hr = pCategoryMgr->RegisterCategory(c_clsidTextService, GUID_TFCAT_TIPCAP_SECUREMODE, c_clsidTextService);
    hr = pCategoryMgr->RegisterCategory(c_clsidTextService, GUID_TFCAT_TIPCAP_COMLESS, c_clsidTextService);
    hr = pCategoryMgr->RegisterCategory(c_clsidTextService, GUID_TFCAT_TIPCAP_INPUTMODECOMPARTMENT, c_clsidTextService);
    hr = pCategoryMgr->RegisterCategory(c_clsidTextService, GUID_TFCAT_TIPCAP_SYSTRAYSUPPORT, c_clsidTextService);

    result = SUCCEEDED(hr);
    pCategoryMgr->Release();

    DebugOut(logTag, L"RegisterCategories END - Result: %s", result ? L"SUCCESS" : L"FAILED");

    return result;
}

static void UnregisterCategories()
{
    DebugOut(logTag, L"UnregisterCategories START");

    ITfCategoryMgr* pCategoryMgr = NULL;
    HRESULT hr;

    hr = CoCreateInstance(CLSID_TF_CategoryMgr, NULL, CLSCTX_INPROC_SERVER,
        IID_ITfCategoryMgr, (void**)&pCategoryMgr);

    if (SUCCEEDED(hr))
    {
        pCategoryMgr->UnregisterCategory(c_clsidTextService, GUID_TFCAT_TIP_KEYBOARD, c_clsidTextService);
        pCategoryMgr->UnregisterCategory(c_clsidTextService, GUID_TFCAT_TIPCAP_IMMERSIVESUPPORT, c_clsidTextService);
        pCategoryMgr->UnregisterCategory(c_clsidTextService, GUID_TFCAT_DISPLAYATTRIBUTEPROVIDER, c_clsidTextService);
        pCategoryMgr->UnregisterCategory(c_clsidTextService, GUID_TFCAT_TIPCAP_UIELEMENTENABLED, c_clsidTextService);

        pCategoryMgr->UnregisterCategory(c_clsidTextService, GUID_TFCAT_TIPCAP_SECUREMODE, c_clsidTextService);
        pCategoryMgr->UnregisterCategory(c_clsidTextService, GUID_TFCAT_TIPCAP_COMLESS, c_clsidTextService);
        pCategoryMgr->UnregisterCategory(c_clsidTextService, GUID_TFCAT_TIPCAP_INPUTMODECOMPARTMENT, c_clsidTextService);
        pCategoryMgr->UnregisterCategory(c_clsidTextService, GUID_TFCAT_TIPCAP_SYSTRAYSUPPORT, c_clsidTextService);

        pCategoryMgr->Release();
    }


    DebugOut(logTag, L"UnregisterCategories END");
}
