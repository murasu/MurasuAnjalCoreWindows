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

// CLSID for the Text Input Processor
// {F7123523-AA20-43CB-8BE3-8AA74E8584F9}
static const GUID c_clsidTextService =
{ 0xF7123523, 0xAA20, 0x43CB, { 0x8B, 0xE3, 0x8A, 0xA7, 0x4E, 0x85, 0x84, 0xF9 } };

// Profile GUID
// {B243DC17-B1C8-496A-B00B-5EB8C3EE4B6F}
static const GUID c_guidProfile =
{ 0xB243DC17, 0xB1C8, 0x496A, { 0xB0, 0x0B, 0x5E, 0xB8, 0xC3, 0xEE, 0x4B, 0x6F } };

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
    STDMETHODIMP QueryInterface(REFIID riid, void** ppvObj);
    STDMETHODIMP_(ULONG) AddRef(void);
    STDMETHODIMP_(ULONG) Release(void);

    // IClassFactory
    STDMETHODIMP CreateInstance(IUnknown* pUnkOuter, REFIID riid, void** ppvObj);
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
    STDMETHODIMP QueryInterface(REFIID riid, void** ppvObj);
    STDMETHODIMP_(ULONG) AddRef(void);
    STDMETHODIMP_(ULONG) Release(void);

    // ITfTextInputProcessor
    STDMETHODIMP Activate(ITfThreadMgr* pThreadMgr, TfClientId tfClientId);
    STDMETHODIMP Deactivate();

    // ITfTextInputProcessorEx
    STDMETHODIMP ActivateEx(ITfThreadMgr* ptim, TfClientId tid, DWORD dwFlags);

    // ITfThreadMgrEventSink
    STDMETHODIMP OnInitDocumentMgr(ITfDocumentMgr* pDocMgr);
    STDMETHODIMP OnUninitDocumentMgr(ITfDocumentMgr* pDocMgr);
    STDMETHODIMP OnSetFocus(ITfDocumentMgr* pDocMgrFocus, ITfDocumentMgr* pDocMgrPrevFocus);
    STDMETHODIMP OnPushContext(ITfContext* pContext);
    STDMETHODIMP OnPopContext(ITfContext* pContext);

    // ITfKeyEventSink
    STDMETHODIMP OnSetFocus(BOOL fForeground);
    STDMETHODIMP OnTestKeyDown(ITfContext* pContext, WPARAM wParam, LPARAM lParam, BOOL* pfEaten);
    STDMETHODIMP OnKeyDown(ITfContext* pContext, WPARAM wParam, LPARAM lParam, BOOL* pfEaten);
    STDMETHODIMP OnTestKeyUp(ITfContext* pContext, WPARAM wParam, LPARAM lParam, BOOL* pfEaten);
    STDMETHODIMP OnKeyUp(ITfContext* pContext, WPARAM wParam, LPARAM lParam, BOOL* pfEaten);
    STDMETHODIMP OnPreservedKey(ITfContext* pContext, REFGUID rguid, BOOL* pfEaten);

    // Helper methods
    BOOL _InitThreadMgrEventSink();
    void _UninitThreadMgrEventSink();
    BOOL _InitKeyEventSink();
    void _UninitKeyEventSink();
    HRESULT _InsertTextAtSelection(ITfContext* pContext, const WCHAR* pchText, ULONG cchText);
    wchar_t _MapKeyToTamil(WPARAM wParam);

private:
    long _refCount;
    TfClientId _tfClientId;
    ITfThreadMgr* _pThreadMgr;
    DWORD _dwThreadMgrEventSinkCookie;
    BOOL _isKeyboardEnabled;

    // Simple Tamil99 mapping - embedded in code, no external files
    static const wchar_t* GetTamilChar(char key);
};

// DLL exports
extern "C" BOOL WINAPI DllMain(HINSTANCE hInstance, DWORD dwReason, LPVOID pvReserved);
extern "C" STDAPI DllCanUnloadNow(void);
extern "C" STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, LPVOID* ppv);
extern "C" STDAPI DllRegisterServer(void);
extern "C" STDAPI DllUnregisterServer(void);

// Globals
extern HINSTANCE g_hInst;
extern LONG g_cRefDll;
