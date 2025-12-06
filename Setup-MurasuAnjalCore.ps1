# Setup-MurasuAnjalCore.ps1
# PowerShell script to create a minimal TSF-based IME project for Tamil keyboards
# Starting with Tamil99, but extensible for other layouts

param(
    [string]$ProjectName = "MurasuAnjalCore",
    [string]$OutputPath = "C:\Users\nedum\Projects\MurasuAnjalCore"
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "MurasuAnjalCore TSF IME Project Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Create project directory structure
Write-Host "Creating project directory structure..." -ForegroundColor Yellow
$Dirs = @(
    $OutputPath,
    "$OutputPath\src",
    "$OutputPath\include",
    "$OutputPath\resources",
    "$OutputPath\build"
)

foreach ($Dir in $Dirs) {
    if (!(Test-Path $Dir)) {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
        Write-Host "  Created: $Dir" -ForegroundColor Green
    }
}

# Generate GUID for COM registration
$CLSID = [guid]::NewGuid().ToString().ToUpper()
$ProfileGuid = [guid]::NewGuid().ToString().ToUpper()

Write-Host ""
Write-Host "Generated GUIDs:" -ForegroundColor Yellow
Write-Host "  CLSID: {$CLSID}" -ForegroundColor Cyan
Write-Host "  Profile GUID: {$ProfileGuid}" -ForegroundColor Cyan

# Create main header file
Write-Host ""
Write-Host "Creating header files..." -ForegroundColor Yellow

$HeaderContent = @"
// MurasuAnjalCore.h
// Minimal TSF-based Input Method Editor for Tamil keyboards
// Starting with Tamil99 layout, extensible for other layouts
// No external dependencies, files, network, or registry access beyond IME registration

#pragma once

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <msctf.h>
#include <olectl.h>
#include <string>

// GUIDs - Replace these with your generated GUIDs
// CLSID for the Text Input Processor
// {$CLSID}
static const GUID c_clsidTextService = 
{ 0x$(($CLSID -split '-')[0]), 0x$(($CLSID -split '-')[1]), 0x$(($CLSID -split '-')[2]), 
  { 0x$(($CLSID -split '-')[3].Substring(0,2)), 0x$(($CLSID -split '-')[3].Substring(2,2)), 
    0x$(($CLSID -split '-')[4].Substring(0,2)), 0x$(($CLSID -split '-')[4].Substring(2,2)),
    0x$(($CLSID -split '-')[4].Substring(4,2)), 0x$(($CLSID -split '-')[4].Substring(6,2)),
    0x$(($CLSID -split '-')[4].Substring(8,2)), 0x$(($CLSID -split '-')[4].Substring(10,2)) } };

// Profile GUID
// {$ProfileGuid}
static const GUID c_guidProfile = 
{ 0x$(($ProfileGuid -split '-')[0]), 0x$(($ProfileGuid -split '-')[1]), 0x$(($ProfileGuid -split '-')[2]), 
  { 0x$(($ProfileGuid -split '-')[3].Substring(0,2)), 0x$(($ProfileGuid -split '-')[3].Substring(2,2)), 
    0x$(($ProfileGuid -split '-')[4].Substring(0,2)), 0x$(($ProfileGuid -split '-')[4].Substring(2,2)),
    0x$(($ProfileGuid -split '-')[4].Substring(4,2)), 0x$(($ProfileGuid -split '-')[4].Substring(6,2)),
    0x$(($ProfileGuid -split '-')[4].Substring(8,2)), 0x$(($ProfileGuid -split '-')[4].Substring(10,2)) } };

// Language - Tamil
static const LANGID c_langid = MAKELANGID(LANG_TAMIL, SUBLANG_DEFAULT);

// Description
#define TEXTSERVICE_DESC    L"Murasu Anjal Core - Tamil99"
#define TEXTSERVICE_MODEL   L"Apartment"

// Forward declarations
class CMurasuAnjalTextService;

// Class Factory
class CClassFactory : public IClassFactory
{
public:
    // IUnknown
    STDMETHODIMP QueryInterface(REFIID riid, void **ppvObj);
    STDMETHODIMP_(ULONG) AddRef(void);
    STDMETHODIMP_(ULONG) Release(void);

    // IClassFactory
    STDMETHODIMP CreateInstance(IUnknown *pUnkOuter, REFIID riid, void **ppvObj);
    STDMETHODIMP LockServer(BOOL fLock);

    CClassFactory() : _refCount(1) {}

private:
    long _refCount;
};

// Murasu Anjal Text Service - Main IME implementation
class CMurasuAnjalTextService : public ITfTextInputProcessor,
                                 public ITfTextInputProcessorEx,
                                 public ITfThreadMgrEventSink,
                                 public ITfKeyEventSink
{
public:
    CMurasuAnjalTextService();
    ~CMurasuAnjalTextService();

    // IUnknown
    STDMETHODIMP QueryInterface(REFIID riid, void **ppvObj);
    STDMETHODIMP_(ULONG) AddRef(void);
    STDMETHODIMP_(ULONG) Release(void);

    // ITfTextInputProcessor
    STDMETHODIMP Activate(ITfThreadMgr *pThreadMgr, TfClientId tfClientId);
    STDMETHODIMP Deactivate();

    // ITfTextInputProcessorEx
    STDMETHODIMP ActivateEx(ITfThreadMgr *ptim, TfClientId tid, DWORD dwFlags);

    // ITfThreadMgrEventSink
    STDMETHODIMP OnInitDocumentMgr(ITfDocumentMgr *pDocMgr);
    STDMETHODIMP OnUninitDocumentMgr(ITfDocumentMgr *pDocMgr);
    STDMETHODIMP OnSetFocus(ITfDocumentMgr *pDocMgrFocus, ITfDocumentMgr *pDocMgrPrevFocus);
    STDMETHODIMP OnPushContext(ITfContext *pContext);
    STDMETHODIMP OnPopContext(ITfContext *pContext);

    // ITfKeyEventSink
    STDMETHODIMP OnSetFocus(BOOL fForeground);
    STDMETHODIMP OnTestKeyDown(ITfContext *pContext, WPARAM wParam, LPARAM lParam, BOOL *pfEaten);
    STDMETHODIMP OnKeyDown(ITfContext *pContext, WPARAM wParam, LPARAM lParam, BOOL *pfEaten);
    STDMETHODIMP OnTestKeyUp(ITfContext *pContext, WPARAM wParam, LPARAM lParam, BOOL *pfEaten);
    STDMETHODIMP OnKeyUp(ITfContext *pContext, WPARAM wParam, LPARAM lParam, BOOL *pfEaten);
    STDMETHODIMP OnPreservedKey(ITfContext *pContext, REFGUID rguid, BOOL *pfEaten);

    // Helper methods
    BOOL _InitThreadMgrEventSink();
    void _UninitThreadMgrEventSink();
    BOOL _InitKeyEventSink();
    void _UninitKeyEventSink();
    HRESULT _InsertTextAtSelection(ITfContext *pContext, const WCHAR *pchText, ULONG cchText);
    wchar_t _MapKeyToTamil(WPARAM wParam);

private:
    long _refCount;
    TfClientId _tfClientId;
    ITfThreadMgr *_pThreadMgr;
    DWORD _dwThreadMgrEventSinkCookie;
    BOOL _isKeyboardEnabled;

    // Simple Tamil99 mapping - embedded in code, no external files
    static const wchar_t* GetTamilChar(char key);
};

// DLL exports
extern "C" BOOL WINAPI DllMain(HINSTANCE hInstance, DWORD dwReason, LPVOID pvReserved);
extern "C" STDAPI DllCanUnloadNow(void);
extern "C" STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, LPVOID *ppv);
extern "C" STDAPI DllRegisterServer(void);
extern "C" STDAPI DllUnregisterServer(void);

// Globals
extern HINSTANCE g_hInst;
extern LONG g_cRefDll;
"@

Set-Content -Path "$OutputPath\include\MurasuAnjalCore.h" -Value $HeaderContent -Encoding UTF8
Write-Host "  Created: MurasuAnjalCore.h" -ForegroundColor Green

# Create main implementation file
$SourceContent = @"
// MurasuAnjalCore.cpp
// Minimal TSF IME implementation with basic Tamil99 character mapping

#include "../include/MurasuAnjalCore.h"
#include <stdio.h>

// Globals
HINSTANCE g_hInst = NULL;
LONG g_cRefDll = 0;

//
// DllMain
//
BOOL WINAPI DllMain(HINSTANCE hInstance, DWORD dwReason, LPVOID pvReserved)
{
    switch (dwReason)
    {
        case DLL_PROCESS_ATTACH:
            g_hInst = hInstance;
            DisableThreadLibraryCalls(hInstance);
            break;
        case DLL_PROCESS_DETACH:
            break;
    }
    return TRUE;
}

//
// DllCanUnloadNow
//
STDAPI DllCanUnloadNow(void)
{
    return (g_cRefDll == 0) ? S_OK : S_FALSE;
}

//
// DllGetClassObject
//
STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, LPVOID *ppv)
{
    if (!ppv)
        return E_INVALIDARG;

    *ppv = NULL;

    if (IsEqualIID(rclsid, c_clsidTextService))
    {
        CClassFactory *pClassFactory = new CClassFactory();
        if (pClassFactory)
        {
            HRESULT hr = pClassFactory->QueryInterface(riid, ppv);
            pClassFactory->Release();
            return hr;
        }
        return E_OUTOFMEMORY;
    }

    return CLASS_E_CLASSNOTAVAILABLE;
}

//
// CClassFactory implementation
//
STDMETHODIMP CClassFactory::QueryInterface(REFIID riid, void **ppvObj)
{
    if (!ppvObj)
        return E_INVALIDARG;

    *ppvObj = NULL;

    if (IsEqualIID(riid, IID_IUnknown) || IsEqualIID(riid, IID_IClassFactory))
    {
        *ppvObj = (IClassFactory *)this;
    }

    if (*ppvObj)
    {
        AddRef();
        return S_OK;
    }

    return E_NOINTERFACE;
}

STDMETHODIMP_(ULONG) CClassFactory::AddRef()
{
    return InterlockedIncrement(&_refCount);
}

STDMETHODIMP_(ULONG) CClassFactory::Release()
{
    LONG cr = InterlockedDecrement(&_refCount);
    if (cr == 0)
    {
        delete this;
    }
    return cr;
}

STDMETHODIMP CClassFactory::CreateInstance(IUnknown *pUnkOuter, REFIID riid, void **ppvObj)
{
    if (!ppvObj)
        return E_INVALIDARG;

    *ppvObj = NULL;

    if (pUnkOuter != NULL)
        return CLASS_E_NOAGGREGATION;

    CMurasuAnjalTextService *pTextService = new CMurasuAnjalTextService();
    if (pTextService == NULL)
        return E_OUTOFMEMORY;

    HRESULT hr = pTextService->QueryInterface(riid, ppvObj);
    pTextService->Release();
    return hr;
}

STDMETHODIMP CClassFactory::LockServer(BOOL fLock)
{
    if (fLock)
        InterlockedIncrement(&g_cRefDll);
    else
        InterlockedDecrement(&g_cRefDll);

    return S_OK;
}

//
// CMurasuAnjalTextService implementation
//
CMurasuAnjalTextService::CMurasuAnjalTextService()
{
    _refCount = 1;
    _tfClientId = TF_CLIENTID_NULL;
    _pThreadMgr = NULL;
    _dwThreadMgrEventSinkCookie = TF_INVALID_COOKIE;
    _isKeyboardEnabled = TRUE;

    InterlockedIncrement(&g_cRefDll);
}

CMurasuAnjalTextService::~CMurasuAnjalTextService()
{
    InterlockedDecrement(&g_cRefDll);
}

STDMETHODIMP CMurasuAnjalTextService::QueryInterface(REFIID riid, void **ppvObj)
{
    if (!ppvObj)
        return E_INVALIDARG;

    *ppvObj = NULL;

    if (IsEqualIID(riid, IID_IUnknown) || IsEqualIID(riid, IID_ITfTextInputProcessor))
    {
        *ppvObj = (ITfTextInputProcessor *)this;
    }
    else if (IsEqualIID(riid, IID_ITfTextInputProcessorEx))
    {
        *ppvObj = (ITfTextInputProcessorEx *)this;
    }
    else if (IsEqualIID(riid, IID_ITfThreadMgrEventSink))
    {
        *ppvObj = (ITfThreadMgrEventSink *)this;
    }
    else if (IsEqualIID(riid, IID_ITfKeyEventSink))
    {
        *ppvObj = (ITfKeyEventSink *)this;
    }

    if (*ppvObj)
    {
        AddRef();
        return S_OK;
    }

    return E_NOINTERFACE;
}

STDMETHODIMP_(ULONG) CMurasuAnjalTextService::AddRef()
{
    return InterlockedIncrement(&_refCount);
}

STDMETHODIMP_(ULONG) CMurasuAnjalTextService::Release()
{
    LONG cr = InterlockedDecrement(&_refCount);
    if (cr == 0)
    {
        delete this;
    }
    return cr;
}

STDMETHODIMP CMurasuAnjalTextService::Activate(ITfThreadMgr *pThreadMgr, TfClientId tfClientId)
{
    _pThreadMgr = pThreadMgr;
    _pThreadMgr->AddRef();
    _tfClientId = tfClientId;

    if (!_InitThreadMgrEventSink())
        return E_FAIL;

    if (!_InitKeyEventSink())
        return E_FAIL;

    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::Deactivate()
{
    _UninitKeyEventSink();
    _UninitThreadMgrEventSink();

    if (_pThreadMgr)
    {
        _pThreadMgr->Release();
        _pThreadMgr = NULL;
    }

    _tfClientId = TF_CLIENTID_NULL;

    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::ActivateEx(ITfThreadMgr *ptim, TfClientId tid, DWORD dwFlags)
{
    return Activate(ptim, tid);
}

// Thread Manager Event Sink
BOOL CMurasuAnjalTextService::_InitThreadMgrEventSink()
{
    ITfSource *pSource = NULL;
    HRESULT hr = _pThreadMgr->QueryInterface(IID_ITfSource, (void **)&pSource);
    
    if (SUCCEEDED(hr))
    {
        hr = pSource->AdviseSink(IID_ITfThreadMgrEventSink, 
                                 (ITfThreadMgrEventSink *)this, 
                                 &_dwThreadMgrEventSinkCookie);
        pSource->Release();
    }

    return SUCCEEDED(hr);
}

void CMurasuAnjalTextService::_UninitThreadMgrEventSink()
{
    if (_dwThreadMgrEventSinkCookie != TF_INVALID_COOKIE)
    {
        ITfSource *pSource = NULL;
        if (SUCCEEDED(_pThreadMgr->QueryInterface(IID_ITfSource, (void **)&pSource)))
        {
            pSource->UnadviseSink(_dwThreadMgrEventSinkCookie);
            pSource->Release();
        }
        _dwThreadMgrEventSinkCookie = TF_INVALID_COOKIE;
    }
}

STDMETHODIMP CMurasuAnjalTextService::OnInitDocumentMgr(ITfDocumentMgr *pDocMgr)
{
    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::OnUninitDocumentMgr(ITfDocumentMgr *pDocMgr)
{
    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::OnSetFocus(ITfDocumentMgr *pDocMgrFocus, ITfDocumentMgr *pDocMgrPrevFocus)
{
    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::OnPushContext(ITfContext *pContext)
{
    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::OnPopContext(ITfContext *pContext)
{
    return S_OK;
}

// Key Event Sink
BOOL CMurasuAnjalTextService::_InitKeyEventSink()
{
    ITfKeystrokeMgr *pKeystrokeMgr = NULL;
    HRESULT hr = _pThreadMgr->QueryInterface(IID_ITfKeystrokeMgr, (void **)&pKeystrokeMgr);
    
    if (SUCCEEDED(hr))
    {
        hr = pKeystrokeMgr->AdviseKeyEventSink(_tfClientId, (ITfKeyEventSink *)this, TRUE);
        pKeystrokeMgr->Release();
    }

    return SUCCEEDED(hr);
}

void CMurasuAnjalTextService::_UninitKeyEventSink()
{
    ITfKeystrokeMgr *pKeystrokeMgr = NULL;
    if (SUCCEEDED(_pThreadMgr->QueryInterface(IID_ITfKeystrokeMgr, (void **)&pKeystrokeMgr)))
    {
        pKeystrokeMgr->UnadviseKeyEventSink(_tfClientId);
        pKeystrokeMgr->Release();
    }
}

STDMETHODIMP CMurasuAnjalTextService::OnSetFocus(BOOL fForeground)
{
    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::OnTestKeyDown(ITfContext *pContext, WPARAM wParam, LPARAM lParam, BOOL *pfEaten)
{
    if (!pfEaten)
        return E_INVALIDARG;

    *pfEaten = FALSE;

    if (!_isKeyboardEnabled)
        return S_OK;

    // Check if this key has a Tamil mapping
    wchar_t tamilChar = _MapKeyToTamil(wParam);
    if (tamilChar != 0)
    {
        *pfEaten = TRUE;
    }

    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::OnKeyDown(ITfContext *pContext, WPARAM wParam, LPARAM lParam, BOOL *pfEaten)
{
    if (!pfEaten)
        return E_INVALIDARG;

    *pfEaten = FALSE;

    if (!_isKeyboardEnabled || !pContext)
        return S_OK;

    // Map key to Tamil character
    wchar_t tamilChar = _MapKeyToTamil(wParam);
    if (tamilChar != 0)
    {
        // Insert the Tamil character
        _InsertTextAtSelection(pContext, &tamilChar, 1);
        *pfEaten = TRUE;
    }

    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::OnTestKeyUp(ITfContext *pContext, WPARAM wParam, LPARAM lParam, BOOL *pfEaten)
{
    if (!pfEaten)
        return E_INVALIDARG;

    *pfEaten = FALSE;
    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::OnKeyUp(ITfContext *pContext, WPARAM wParam, LPARAM lParam, BOOL *pfEaten)
{
    if (!pfEaten)
        return E_INVALIDARG;

    *pfEaten = FALSE;
    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::OnPreservedKey(ITfContext *pContext, REFGUID rguid, BOOL *pfEaten)
{
    if (!pfEaten)
        return E_INVALIDARG;

    *pfEaten = FALSE;
    return S_OK;
}

// Helper: Insert text at current selection
HRESULT CMurasuAnjalTextService::_InsertTextAtSelection(ITfContext *pContext, const WCHAR *pchText, ULONG cchText)
{
    ITfInsertAtSelection *pInsertAtSelection = NULL;
    ITfRange *pRange = NULL;
    HRESULT hr;

    hr = pContext->QueryInterface(IID_ITfInsertAtSelection, (void **)&pInsertAtSelection);
    if (SUCCEEDED(hr))
    {
        hr = pInsertAtSelection->InsertTextAtSelection(TF_IAS_QUERYONLY, 
                                                       pchText, 
                                                       cchText, 
                                                       &pRange);
        if (SUCCEEDED(hr))
        {
            hr = pRange->SetText(0, 0, pchText, cchText);
            pRange->Release();
        }
        pInsertAtSelection->Release();
    }

    return hr;
}

// Tamil99 character mapping - MINIMAL DEMO VERSION
// This maps just a few keys to demonstrate the concept
// You'll expand this with the full Tamil99 layout
wchar_t CMurasuAnjalTextService::_MapKeyToTamil(WPARAM wParam)
{
    // Basic Tamil99 mapping (partial - for demonstration)
    // Format: English key -> Tamil character
    switch (wParam)
    {
        // Vowels
        case 'A': return 0x0B85;  // அ
        case 'S': return 0x0B86;  // ஆ
        case 'D': return 0x0B87;  // இ
        case 'F': return 0x0B88;  // ஈ
        case 'G': return 0x0B89;  // உ
        case 'H': return 0x0B8A;  // ஊ
        
        // Consonants
        case 'Q': return 0x0B95;  // க
        case 'W': return 0x0B99;  // ங
        case 'E': return 0x0B9A;  // ச
        case 'R': return 0x0B9E;  // ஞ
        case 'T': return 0x0B9F;  // ட
        case 'Y': return 0x0BA3;  // ண
        
        // Add more mappings here for full Tamil99 layout
        
        default:
            return 0;  // No mapping
    }
}

// Simple mapping table accessor (for future expansion)
const wchar_t* CMurasuAnjalTextService::GetTamilChar(char key)
{
    // This can be expanded to return full character sequences if needed
    static wchar_t buffer[2] = {0};
    buffer[0] = 0;
    
    // For now, return single character mapping
    // This method allows for future expansion to support conjuncts
    
    return buffer;
}
"@

Set-Content -Path "$OutputPath\src\MurasuAnjalCore.cpp" -Value $SourceContent -Encoding UTF8
Write-Host "  Created: MurasuAnjalCore.cpp" -ForegroundColor Green

# Create registration implementation
$RegContent = @"
// Register.cpp
// COM registration for MurasuAnjalCore TSF IME

#include "../include/MurasuAnjalCore.h"
#include <olectl.h>
#include <strsafe.h>

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
    if (!RegisterServer())
        return E_FAIL;

    if (!RegisterProfiles())
    {
        DllUnregisterServer();
        return E_FAIL;
    }

    if (!RegisterCategories())
    {
        DllUnregisterServer();
        return E_FAIL;
    }

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
    HKEY hKey = NULL;
    HKEY hSubKey = NULL;
    LONG result;
    WCHAR achIMEKey[512];
    WCHAR achFileName[MAX_PATH];
    DWORD dw;

    // Get DLL path
    if (!GetModuleFileNameW(g_hInst, achFileName, ARRAYSIZE(achFileName)))
        return FALSE;

    // Register CLSID
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

    result = RegCreateKeyExW(HKEY_CLASSES_ROOT, achIMEKey, 0, NULL, 
                             REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &hKey, &dw);
    if (result != ERROR_SUCCESS)
        return FALSE;

    // Set description
    RegSetValueExW(hKey, NULL, 0, REG_SZ, 
                   (BYTE *)TEXTSERVICE_DESC, 
                   (lstrlenW(TEXTSERVICE_DESC) + 1) * sizeof(WCHAR));

    // InprocServer32
    result = RegCreateKeyExW(hKey, L"InprocServer32", 0, NULL, 
                             REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &hSubKey, &dw);
    if (result == ERROR_SUCCESS)
    {
        RegSetValueExW(hSubKey, NULL, 0, REG_SZ, 
                      (BYTE *)achFileName, 
                      (lstrlenW(achFileName) + 1) * sizeof(WCHAR));
        
        RegSetValueExW(hSubKey, L"ThreadingModel", 0, REG_SZ, 
                      (BYTE *)TEXTSERVICE_MODEL, 
                      (lstrlenW(TEXTSERVICE_MODEL) + 1) * sizeof(WCHAR));
        
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

static BOOL RegisterProfiles()
{
    ITfInputProcessorProfiles *pInputProcessorProfiles = NULL;
    HRESULT hr;
    BOOL result = FALSE;

    hr = CoCreateInstance(CLSID_TF_InputProcessorProfiles, NULL, CLSCTX_INPROC_SERVER,
                         IID_ITfInputProcessorProfiles, (void **)&pInputProcessorProfiles);

    if (SUCCEEDED(hr))
    {
        hr = pInputProcessorProfiles->Register(c_clsidTextService);
        if (SUCCEEDED(hr))
        {
            hr = pInputProcessorProfiles->AddLanguageProfile(
                c_clsidTextService,
                c_langid,
                c_guidProfile,
                TEXTSERVICE_DESC,
                lstrlenW(TEXTSERVICE_DESC),
                NULL,  // No icon file for minimal version
                0,
                0);
            
            result = SUCCEEDED(hr);
        }
        pInputProcessorProfiles->Release();
    }

    return result;
}

static void UnregisterProfiles()
{
    ITfInputProcessorProfiles *pInputProcessorProfiles = NULL;
    HRESULT hr;

    hr = CoCreateInstance(CLSID_TF_InputProcessorProfiles, NULL, CLSCTX_INPROC_SERVER,
                         IID_ITfInputProcessorProfiles, (void **)&pInputProcessorProfiles);

    if (SUCCEEDED(hr))
    {
        pInputProcessorProfiles->Unregister(c_clsidTextService);
        pInputProcessorProfiles->Release();
    }
}

static BOOL RegisterCategories()
{
    ITfCategoryMgr *pCategoryMgr = NULL;
    HRESULT hr;
    BOOL result = FALSE;

    hr = CoCreateInstance(CLSID_TF_CategoryMgr, NULL, CLSCTX_INPROC_SERVER,
                         IID_ITfCategoryMgr, (void **)&pCategoryMgr);

    if (SUCCEEDED(hr))
    {
        // Register as a keyboard input processor
        hr = pCategoryMgr->RegisterCategory(c_clsidTextService,
                                           GUID_TFCAT_TIP_KEYBOARD,
                                           c_clsidTextService);

        result = SUCCEEDED(hr);
        pCategoryMgr->Release();
    }

    return result;
}

static void UnregisterCategories()
{
    ITfCategoryMgr *pCategoryMgr = NULL;
    HRESULT hr;

    hr = CoCreateInstance(CLSID_TF_CategoryMgr, NULL, CLSCTX_INPROC_SERVER,
                         IID_ITfCategoryMgr, (void **)&pCategoryMgr);

    if (SUCCEEDED(hr))
    {
        pCategoryMgr->UnregisterCategory(c_clsidTextService,
                                        GUID_TFCAT_TIP_KEYBOARD,
                                        c_clsidTextService);
        pCategoryMgr->Release();
    }
}
"@

Set-Content -Path "$OutputPath\src\Register.cpp" -Value $RegContent -Encoding UTF8
Write-Host "  Created: Register.cpp" -ForegroundColor Green

# Create DEF file
$DefContent = @"
LIBRARY MurasuAnjalCore
EXPORTS
    DllCanUnloadNow     PRIVATE
    DllGetClassObject   PRIVATE
    DllRegisterServer   PRIVATE
    DllUnregisterServer PRIVATE
"@

Set-Content -Path "$OutputPath\src\MurasuAnjalCore.def" -Value $DefContent -Encoding UTF8
Write-Host "  Created: MurasuAnjalCore.def" -ForegroundColor Green

# Create Visual Studio project file
$VCXProjContent = @"
<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <ItemGroup Label="ProjectConfigurations">
    <ProjectConfiguration Include="Debug|x64">
      <Configuration>Debug</Configuration>
      <Platform>x64</Platform>
    </ProjectConfiguration>
    <ProjectConfiguration Include="Release|x64">
      <Configuration>Release</Configuration>
      <Platform>x64</Platform>
    </ProjectConfiguration>
  </ItemGroup>
  <PropertyGroup Label="Globals">
    <ProjectGuid>{$([guid]::NewGuid().ToString().ToUpper())}</ProjectGuid>
    <Keyword>Win32Proj</Keyword>
    <RootNamespace>MurasuAnjalCore</RootNamespace>
    <WindowsTargetPlatformVersion>10.0</WindowsTargetPlatformVersion>
  </PropertyGroup>
  <Import Project="`$(VCTargetsPath)\Microsoft.Cpp.Default.props" />
  <PropertyGroup Condition="'`$(Configuration)|`$(Platform)'=='Debug|x64'" Label="Configuration">
    <ConfigurationType>DynamicLibrary</ConfigurationType>
    <UseDebugLibraries>true</UseDebugLibraries>
    <PlatformToolset>v143</PlatformToolset>
    <CharacterSet>Unicode</CharacterSet>
  </PropertyGroup>
  <PropertyGroup Condition="'`$(Configuration)|`$(Platform)'=='Release|x64'" Label="Configuration">
    <ConfigurationType>DynamicLibrary</ConfigurationType>
    <UseDebugLibraries>false</UseDebugLibraries>
    <PlatformToolset>v143</PlatformToolset>
    <WholeProgramOptimization>true</WholeProgramOptimization>
    <CharacterSet>Unicode</CharacterSet>
  </PropertyGroup>
  <Import Project="`$(VCTargetsPath)\Microsoft.Cpp.props" />
  <ImportGroup Label="PropertySheets" Condition="'`$(Configuration)|`$(Platform)'=='Debug|x64'">
    <Import Project="`$(UserRootDir)\Microsoft.Cpp.`$(Platform).user.props" Condition="exists('`$(UserRootDir)\Microsoft.Cpp.`$(Platform).user.props')" Label="LocalAppDataPlatform" />
  </ImportGroup>
  <ImportGroup Label="PropertySheets" Condition="'`$(Configuration)|`$(Platform)'=='Release|x64'">
    <Import Project="`$(UserRootDir)\Microsoft.Cpp.`$(Platform).user.props" Condition="exists('`$(UserRootDir)\Microsoft.Cpp.`$(Platform).user.props')" Label="LocalAppDataPlatform" />
  </ImportGroup>
  <PropertyGroup Condition="'`$(Configuration)|`$(Platform)'=='Debug|x64'">
    <LinkIncremental>true</LinkIncremental>
    <OutDir>`$(SolutionDir)build\Debug\</OutDir>
    <IntDir>`$(SolutionDir)build\Debug\obj\</IntDir>
  </PropertyGroup>
  <PropertyGroup Condition="'`$(Configuration)|`$(Platform)'=='Release|x64'">
    <LinkIncremental>false</LinkIncremental>
    <OutDir>`$(SolutionDir)build\Release\</OutDir>
    <IntDir>`$(SolutionDir)build\Release\obj\</IntDir>
  </PropertyGroup>
  <ItemDefinitionGroup Condition="'`$(Configuration)|`$(Platform)'=='Debug|x64'">
    <ClCompile>
      <PrecompiledHeader>NotUsing</PrecompiledHeader>
      <WarningLevel>Level3</WarningLevel>
      <Optimization>Disabled</Optimization>
      <PreprocessorDefinitions>_DEBUG;_WINDOWS;_USRDLL;%(PreprocessorDefinitions)</PreprocessorDefinitions>
      <SDLCheck>true</SDLCheck>
      <AdditionalIncludeDirectories>`$(ProjectDir)include;%(AdditionalIncludeDirectories)</AdditionalIncludeDirectories>
    </ClCompile>
    <Link>
      <SubSystem>Windows</SubSystem>
      <ModuleDefinitionFile>src\MurasuAnjalCore.def</ModuleDefinitionFile>
      <AdditionalDependencies>kernel32.lib;user32.lib;ole32.lib;oleaut32.lib;uuid.lib;%(AdditionalDependencies)</AdditionalDependencies>
    </Link>
  </ItemDefinitionGroup>
  <ItemDefinitionGroup Condition="'`$(Configuration)|`$(Platform)'=='Release|x64'">
    <ClCompile>
      <WarningLevel>Level3</WarningLevel>
      <PrecompiledHeader>NotUsing</PrecompiledHeader>
      <Optimization>MaxSpeed</Optimization>
      <FunctionLevelLinking>true</FunctionLevelLinking>
      <IntrinsicFunctions>true</IntrinsicFunctions>
      <PreprocessorDefinitions>NDEBUG;_WINDOWS;_USRDLL;%(PreprocessorDefinitions)</PreprocessorDefinitions>
      <SDLCheck>true</SDLCheck>
      <AdditionalIncludeDirectories>`$(ProjectDir)include;%(AdditionalIncludeDirectories)</AdditionalIncludeDirectories>
    </ClCompile>
    <Link>
      <SubSystem>Windows</SubSystem>
      <EnableCOMDATFolding>true</EnableCOMDATFolding>
      <OptimizeReferences>true</OptimizeReferences>
      <ModuleDefinitionFile>src\MurasuAnjalCore.def</ModuleDefinitionFile>
      <AdditionalDependencies>kernel32.lib;user32.lib;ole32.lib;oleaut32.lib;uuid.lib;%(AdditionalDependencies)</AdditionalDependencies>
    </Link>
  </ItemDefinitionGroup>
  <ItemGroup>
    <ClCompile Include="src\MurasuAnjalCore.cpp" />
    <ClCompile Include="src\Register.cpp" />
  </ItemGroup>
  <ItemGroup>
    <ClInclude Include="include\MurasuAnjalCore.h" />
  </ItemGroup>
  <ItemGroup>
    <None Include="src\MurasuAnjalCore.def" />
  </ItemGroup>
  <Import Project="`$(VCTargetsPath)\Microsoft.Cpp.targets" />
</Project>
"@

Set-Content -Path "$OutputPath\MurasuAnjalCore.vcxproj" -Value $VCXProjContent -Encoding UTF8
Write-Host "  Created: MurasuAnjalCore.vcxproj" -ForegroundColor Green

# Create installation script
$InstallScript = @"
@echo off
REM Install-MurasuAnjalCore.bat
REM Installation script for Murasu Anjal Core TSF IME
REM Must be run as Administrator

echo ============================================
echo Murasu Anjal Core - Tamil99 IME Installation
echo ============================================
echo.

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script must be run as Administrator
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

REM Determine architecture
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set DLL_PATH="%~dp0build\Release\MurasuAnjalCore.dll"
) else (
    set DLL_PATH="%~dp0build\Release\MurasuAnjalCore.dll"
)

if not exist %DLL_PATH% (
    echo ERROR: MurasuAnjalCore.dll not found
    echo Please build the project first using Visual Studio
    pause
    exit /b 1
)

echo Installing Murasu Anjal Core Tamil99 IME...
echo.

REM Register the DLL
regsvr32 /s %DLL_PATH%
if %errorLevel% neq 0 (
    echo ERROR: Registration failed
    pause
    exit /b 1
)

echo.
echo ============================================
echo Installation Complete!
echo ============================================
echo.
echo Next steps:
echo 1. Go to Settings ^> Time ^& Language ^> Language ^& region
echo 2. Click "Add a language"
echo 3. Search for "Tamil"
echo 4. Add Tamil language
echo 5. Click Options next to Tamil
echo 6. Under Keyboards, you should see "Murasu Anjal Core - Tamil99"
echo 7. Configure the floating language bar (see README.md)
echo.
echo For Respondus LockDown Browser:
echo - Enable floating desktop language bar
echo - Set up keyboard hotkeys for switching
echo.
pause
"@

Set-Content -Path "$OutputPath\Install-MurasuAnjalCore.bat" -Value $InstallScript -Encoding UTF8
Write-Host "  Created: Install-MurasuAnjalCore.bat" -ForegroundColor Green

# Create uninstallation script
$UninstallScript = @"
@echo off
REM Uninstall-MurasuAnjalCore.bat
REM Uninstallation script for Murasu Anjal Core TSF IME
REM Must be run as Administrator

echo ============================================
echo Murasu Anjal Core - Tamil99 IME Uninstallation
echo ============================================
echo.

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script must be run as Administrator
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

set DLL_PATH="%~dp0build\Release\MurasuAnjalCore.dll"

if not exist %DLL_PATH% (
    echo WARNING: MurasuAnjalCore.dll not found
    echo The IME may have already been uninstalled
    pause
    exit /b 0
)

echo Uninstalling Murasu Anjal Core Tamil99 IME...
echo.

REM Unregister the DLL
regsvr32 /u /s %DLL_PATH%

echo.
echo ============================================
echo Uninstallation Complete!
echo ============================================
echo.
pause
"@

Set-Content -Path "$OutputPath\Uninstall-MurasuAnjalCore.bat" -Value $UninstallScript -Encoding UTF8
Write-Host "  Created: Uninstall-MurasuAnjalCore.bat" -ForegroundColor Green

# Create README
$ReadmeContent = @"
# Murasu Anjal Core - Tamil TSF IME

A minimal Text Services Framework (TSF) based Input Method Editor (IME) for Tamil keyboards, designed specifically for compatibility with Respondus LockDown Browser and other restricted environments.

## Project Goals

- **Extensible**: Starting with Tamil99, but designed to support additional Tamil keyboard layouts
- **Minimal**: No external dependencies, network access, or file system operations beyond installation
- **Secure**: Works in restricted exam environments like Respondus LockDown Browser
- **Modern**: TSF-based architecture for best Windows compatibility

## Current Implementation

This initial release supports basic Tamil99 keyboard layout with demonstration character mappings. Full Tamil99 layout can be added by expanding the mapping table.

## System Requirements

- Windows 10/11 (64-bit)
- Visual Studio 2022 or later with C++ Desktop Development workload
- Administrator privileges for installation

## Build Instructions

1. Open `MurasuAnjalCore.vcxproj` in Visual Studio 2022
2. Select **Release** configuration and **x64** platform
3. Build Solution (Ctrl+Shift+B)
4. The DLL will be created in `build\Release\MurasuAnjalCore.dll`

## Installation

1. Build the project (see above)
2. Right-click `Install-MurasuAnjalCore.bat` and select **Run as administrator**
3. Follow the on-screen instructions

### Manual Windows Configuration

After installation:

1. Go to **Settings** > **Time & Language** > **Language & region**
2. Add Tamil language if not already added
3. Click **Options** next to Tamil
4. "Murasu Anjal Core - Tamil99" should appear under Keyboards

### For Respondus LockDown Browser

**Important**: Configure these settings BEFORE launching LockDown Browser:

1. Go to **Settings** > **Time & Language** > **Typing** > **Advanced keyboard settings**
2. Enable:
   - "Let me use a different input method for each app window"
   - "Use the desktop language bar when it's available"
3. Click "Language bar options"
4. Select "Floating on Desktop" (NOT "Docked in the taskbar")
5. Click Apply

**Keyboard Switching**:
- Set up hotkeys: **Settings** > **Typing** > **Advanced Keyboard Settings** > **Input Language Hot Keys**
- Common combinations: Left Alt + Shift or Ctrl + Shift

## Current Character Mapping (Demo)

This is a demonstration version with basic mappings:

| Key | Tamil Character | Unicode | Description |
|-----|-----------------|---------|-------------|
| A   | அ               | U+0B85  | Vowel A     |
| S   | ஆ               | U+0B86  | Vowel AA    |
| D   | இ               | U+0B87  | Vowel I     |
| F   | ஈ               | U+0B88  | Vowel II    |
| G   | உ               | U+0B89  | Vowel U     |
| H   | ஊ               | U+0B8A  | Vowel UU    |
| Q   | க               | U+0B95  | Ka          |
| W   | ங               | U+0B99  | Nga         |
| E   | ச               | U+0B9A  | Ca          |
| R   | ஞ               | U+0B9E  | Nya         |
| T   | ட               | U+0B9F  | Tta         |
| Y   | ண               | U+0BA3  | Nna         |

## Expanding the Tamil99 Layout

To add the complete Tamil99 mapping:

1. Open `src\MurasuAnjalCore.cpp`
2. Find the `_MapKeyToTamil()` function (around line 280)
3. Add more case statements following the pattern:

\`\`\`cpp
// More consonants
case 'U': return 0x0BA4;  // த (tha)
case 'I': return 0x0BA8;  // ந (na)
case 'O': return 0x0BAA;  // ப (pa)
case 'P': return 0x0BAE;  // ம (ma)

// More vowels
case 'J': return 0x0B8E;  // எ (e)
case 'K': return 0x0B8F;  // ஏ (ee)
case 'L': return 0x0B90;  // ஐ (ai)

// Add all remaining Tamil99 mappings...
\`\`\`

4. Rebuild the project
5. Uninstall the old version
6. Install the new version

## Future Keyboard Layouts

The architecture supports adding additional Tamil keyboard layouts:

1. Add layout-specific mapping functions
2. Add layout selection mechanism
3. Register additional profiles in `Register.cpp`

Possible future layouts:
- Tamil Typewriter
- Phonetic Tamil
- InScript Tamil
- Custom layouts

## Troubleshooting

### IME doesn't appear in keyboard list
- Ensure you ran installation as Administrator
- Check if Tamil language is added to Windows
- Restart Windows after installation

### Doesn't work in LockDown Browser
- Verify floating language bar is enabled (see configuration above)
- Test hotkey switching in regular Notepad first
- Ensure you're using the latest build

### Build errors
- Verify Visual Studio has C++ Desktop Development workload installed
- Check Windows SDK is installed (10.0 or later)
- Clean solution and rebuild

### Characters not appearing correctly
- Ensure you have Tamil fonts installed (Windows includes Latha, Vijaya)
- Test in different applications (Notepad, Word, browser)

## Uninstallation

1. Right-click `Uninstall-MurasuAnjalCore.bat` and select **Run as administrator**
2. Remove Tamil keyboard from Windows Language settings if desired

## Architecture

This IME implements the minimum TSF interfaces required:

- `ITfTextInputProcessor` - Main processor interface
- `ITfTextInputProcessorEx` - Extended activation
- `ITfThreadMgrEventSink` - Thread manager events
- `ITfKeyEventSink` - Keyboard event handling

The implementation is intentionally minimal to avoid conflicts in restricted environments:
- No candidate windows or UI elements
- No dictionary files or external resources
- No network or internet access
- No user preferences or settings files
- Direct character insertion only

## GUIDs

This installation uses:
- CLSID: {$CLSID}
- Profile GUID: {$ProfileGuid}

## Project Structure

\`\`\`
MurasuAnjalCore/
├── include/
│   └── MurasuAnjalCore.h          # Main header with TSF interfaces
├── src/
│   ├── MurasuAnjalCore.cpp        # Core IME implementation
│   ├── Register.cpp               # COM registration
│   └── MurasuAnjalCore.def        # DLL exports
├── build/                         # Build output
├── MurasuAnjalCore.vcxproj        # Visual Studio project
├── Install-MurasuAnjalCore.bat    # Installation script
├── Uninstall-MurasuAnjalCore.bat  # Uninstallation script
└── README.md                      # This file
\`\`\`

## Contributing

When adding new keyboard layouts:
1. Follow the minimal design principle
2. Embed all mappings in code (no external files)
3. Test in LockDown Browser environment
4. Update documentation

## License

This is a minimal reference implementation for educational and exam purposes.

## About Murasu Anjal

"Anjal" (அஞ்சல்) means "letter" or "character" in Tamil. This project aims to provide reliable, exam-safe Tamil input methods for Windows systems.

## Support

For issues specific to:
- Singapore MOE exam deployment: Consult your system administrator
- Respondus LockDown Browser compatibility: See troubleshooting section
- General TSF/Windows issues: Check Windows Event Viewer for registration errors

## Version History

- v0.1 (Initial): Basic Tamil99 demo with 12 character mappings
- Future: Complete Tamil99 layout, additional keyboard layouts
"@

Set-Content -Path "$OutputPath\README.md" -Value $ReadmeContent -Encoding UTF8
Write-Host "  Created: README.md" -ForegroundColor Green

# Create .gitignore
$GitignoreContent = @"
# Build directories
build/
*.dll
*.pdb
*.obj
*.lib
*.exp

# Visual Studio
.vs/
*.user
*.suo
*.sdf
*.opensdf
*.VC.db
*.VC.opendb

# Logs
*.log
"@

Set-Content -Path "$OutputPath\.gitignore" -Value $GitignoreContent -Encoding UTF8
Write-Host "  Created: .gitignore" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Project Setup Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Project Location: $OutputPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "Generated GUIDs (saved in project):" -ForegroundColor Yellow
Write-Host "  CLSID: {$CLSID}" -ForegroundColor Cyan
Write-Host "  Profile: {$ProfileGuid}" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Open $OutputPath\MurasuAnjalCore.vcxproj in Visual Studio 2022" -ForegroundColor White
Write-Host "  2. Select Release configuration, x64 platform" -ForegroundColor White
Write-Host "  3. Build Solution (Ctrl+Shift+B)" -ForegroundColor White
Write-Host "  4. Run Install-MurasuAnjalCore.bat as Administrator" -ForegroundColor White
Write-Host "  5. Test in Notepad, then in LockDown Browser practice exam" -ForegroundColor White
Write-Host ""
Write-Host "The basic Tamil99 mapping is implemented for demo purposes." -ForegroundColor Yellow
Write-Host "You can expand it later by editing src\MurasuAnjalCore.cpp" -ForegroundColor Yellow
Write-Host ""
Write-Host "Project Name: MurasuAnjalCore" -ForegroundColor Cyan
Write-Host "  - Extensible for multiple Tamil keyboard layouts" -ForegroundColor Gray
Write-Host "  - Starting with Tamil99" -ForegroundColor Gray
Write-Host ""
Write-Host "See README.md for complete instructions." -ForegroundColor Cyan
Write-Host ""
