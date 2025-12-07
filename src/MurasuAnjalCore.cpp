// MurasuAnjalCore.cpp
// Minimal TSF IME implementation with basic Tamil99 character mapping

#include "../include/MurasuAnjalCore.h"
#include <stdio.h>
#include "../include/Debug.h"

// Globals
HINSTANCE g_hInst = NULL;
LONG g_cRefDll = 0;

//
// Edit Session for inserting text
//
class CEditSession : public ITfEditSession
{
public:
    CEditSession(ITfContext* pContext, const WCHAR* pchText, ULONG cchText)
    {
        _refCount = 1;
        _pContext = pContext;
        _pContext->AddRef();
        _cchText = cchText;
        _pchText = new WCHAR[cchText + 1];
        if (_pchText)
        {
            memcpy(_pchText, pchText, cchText * sizeof(WCHAR));
            _pchText[cchText] = 0;
        }
    }

    ~CEditSession()
    {
        if (_pContext)
            _pContext->Release();
        if (_pchText)
            delete[] _pchText;
    }

    // IUnknown
    STDMETHODIMP QueryInterface(REFIID riid, void** ppvObj)
    {
        if (!ppvObj)
            return E_INVALIDARG;

        *ppvObj = NULL;

        if (IsEqualIID(riid, IID_IUnknown) || IsEqualIID(riid, IID_ITfEditSession))
        {
            *ppvObj = (ITfEditSession*)this;
        }

        if (*ppvObj)
        {
            AddRef();
            return S_OK;
        }

        return E_NOINTERFACE;
    }

    STDMETHODIMP_(ULONG) AddRef()
    {
        return InterlockedIncrement(&_refCount);
    }

    STDMETHODIMP_(ULONG) Release()
    {
        LONG cr = InterlockedDecrement(&_refCount);
        if (cr == 0)
        {
            delete this;
        }
        return cr;
    }

    // ITfEditSession
    STDMETHODIMP DoEditSession(TfEditCookie ec)
    {
        DebugOut(logTag, L"      DoEditSession START");

        HRESULT hr = E_FAIL;
        ITfInsertAtSelection* pInsertAtSelection = NULL;
        ITfRange* pRange = NULL;

        hr = _pContext->QueryInterface(IID_ITfInsertAtSelection, (void**)&pInsertAtSelection);
        DebugOut(logTag, L"        QI ITfInsertAtSelection: 0x%08X", hr);

        if (SUCCEEDED(hr))
        {
            DebugOut(logTag, L"        Method: QUERYONLY + SetText + Move cursor");

            // Get the current selection range
            hr = pInsertAtSelection->InsertTextAtSelection(ec,
                TF_IAS_QUERYONLY,
                NULL,
                0,
                &pRange);

            DebugOut(logTag, L"        InsertTextAtSelection(QUERYONLY): 0x%08X", hr);

            if (SUCCEEDED(hr) && pRange)
            {
                // Collapse to insertion point (start of selection)
                hr = pRange->Collapse(ec, TF_ANCHOR_START);
                DebugOut(logTag, L"        Collapse to START: 0x%08X", hr);

                // Insert the text
                hr = pRange->SetText(ec, 0, _pchText, _cchText);
                DebugOut(logTag, L"        SetText: 0x%08X", hr);

                if (SUCCEEDED(hr))
                {
                    // ✅ Move the range to END of the text we just inserted
                    // ShiftEnd moves the end anchor forward by the length of text
                    LONG cch;
                    hr = pRange->ShiftEnd(ec, _cchText, &cch, NULL);
                    DebugOut(logTag, L"        ShiftEnd(%d chars): 0x%08X, moved=%d", _cchText, hr, cch);

                    // Collapse to the end (this puts both anchors at the end)
                    hr = pRange->Collapse(ec, TF_ANCHOR_END);
                    DebugOut(logTag, L"        Collapse to END: 0x%08X", hr);

                    // Set this as the new selection (cursor position)
                    TF_SELECTION tfSelection;
                    tfSelection.range = pRange;
                    tfSelection.style.ase = TF_AE_END;  // Active end is at the end
                    tfSelection.style.fInterimChar = FALSE;

                    hr = _pContext->SetSelection(ec, 1, &tfSelection);
                    DebugOut(logTag, L"        SetSelection: 0x%08X", hr);
                }

                pRange->Release();
            }

            pInsertAtSelection->Release();
        }

        DebugOut(logTag, L"      DoEditSession END: 0x%08X", hr);
        return hr;
    }

private:
    long _refCount;
    ITfContext* _pContext;
    WCHAR* _pchText;
    ULONG _cchText;
};

//
// DllMain
//
BOOL WINAPI DllMain(HINSTANCE hInstance, DWORD dwReason, LPVOID pvReserved)
{
    switch (dwReason)
    {
    case DLL_PROCESS_ATTACH:
        DebugOut(logTag, L"DLL_PROCESS_ATTACH");
        g_hInst = hInstance;
        DisableThreadLibraryCalls(hInstance);
        break;
    case DLL_PROCESS_DETACH:
        DebugOut(logTag, L"DLL_PROCESS_DETACH");
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
STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, LPVOID* ppv)
{
	DebugOut(logTag, L"DllGetClassObject called!");

    // Show which CLSID was requested
    WCHAR msg[200];
    LPOLESTR clsidStr;
    StringFromCLSID(rclsid, &clsidStr);
    DebugOut(logTag, L"Requested CLSID: %s", clsidStr);

    CoTaskMemFree(clsidStr);
	// end show CLSID

    if (!ppv)
        return E_INVALIDARG;

    *ppv = NULL;

    if (IsEqualIID(rclsid, c_clsidTextService))
    {
        CClassFactory* pClassFactory = new CClassFactory();
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
STDMETHODIMP CClassFactory::QueryInterface(REFIID riid, void** ppvObj)
{
    if (!ppvObj)
        return E_INVALIDARG;

    *ppvObj = NULL;

    if (IsEqualIID(riid, IID_IUnknown) || IsEqualIID(riid, IID_IClassFactory))
    {
        *ppvObj = (IClassFactory*)this;
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

STDMETHODIMP CClassFactory::CreateInstance(IUnknown* pUnkOuter, REFIID riid, void** ppvObj)
{
	DebugOut(logTag, L"CreateInstance called!");

    if (!ppvObj)
        return E_INVALIDARG;

    *ppvObj = NULL;

    if (pUnkOuter != NULL)
        return CLASS_E_NOAGGREGATION;

    CMurasuAnjalTextService* pTextService = new CMurasuAnjalTextService();
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

STDMETHODIMP CMurasuAnjalTextService::QueryInterface(REFIID riid, void** ppvObj)
{
    if (!ppvObj)
        return E_INVALIDARG;

    *ppvObj = NULL;

    if (IsEqualIID(riid, IID_IUnknown) || IsEqualIID(riid, IID_ITfTextInputProcessor))
    {
        *ppvObj = (ITfTextInputProcessor*)this;
    }
    else if (IsEqualIID(riid, IID_ITfTextInputProcessorEx))
    {
        *ppvObj = (ITfTextInputProcessorEx*)this;
    }
    else if (IsEqualIID(riid, IID_ITfThreadMgrEventSink))
    {
        *ppvObj = (ITfThreadMgrEventSink*)this;
    }
    else if (IsEqualIID(riid, IID_ITfKeyEventSink))
    {
        *ppvObj = (ITfKeyEventSink*)this;
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

STDMETHODIMP CMurasuAnjalTextService::Activate(ITfThreadMgr* pThreadMgr, TfClientId tfClientId)
{
	DebugOut(logTag, L"Activate() called!");

    _pThreadMgr = pThreadMgr;
    _pThreadMgr->AddRef();
    _tfClientId = tfClientId;

    if (!_InitThreadMgrEventSink())
        return E_FAIL;

    if (!_InitKeyEventSink())
        return E_FAIL;

    // Check what app we are attaching to
    ITfThreadMgrEx* pThreadMgrEx = NULL;
    if (SUCCEEDED(_pThreadMgr->QueryInterface(IID_ITfThreadMgrEx, (void**)&pThreadMgrEx)))
    {
        DWORD dwFlags = 0;
        pThreadMgrEx->GetActiveFlags(&dwFlags);

        if (dwFlags & TF_TMF_IMMERSIVEMODE)
        {
            // Running in UWP app (Search, Settings, etc.)
            DebugOut(logTag, L"Running in IMMERSIVE MODE (UWP)");
        }
        else
        {
            // Running in desktop app
            DebugOut(logTag, L"Running in DESKTOP MODE");
        }

        pThreadMgrEx->Release();
    }
	// End check app

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

STDMETHODIMP CMurasuAnjalTextService::ActivateEx(ITfThreadMgr* ptim, TfClientId tid, DWORD dwFlags)
{
	DebugOut(logTag, L"ActivateEx() called!");

    return Activate(ptim, tid);
}

// Thread Manager Event Sink
BOOL CMurasuAnjalTextService::_InitThreadMgrEventSink()
{
    ITfSource* pSource = NULL;
    HRESULT hr = _pThreadMgr->QueryInterface(IID_ITfSource, (void**)&pSource);

    if (SUCCEEDED(hr))
    {
        hr = pSource->AdviseSink(IID_ITfThreadMgrEventSink,
            (ITfThreadMgrEventSink*)this,
            &_dwThreadMgrEventSinkCookie);
        pSource->Release();
    }

    return SUCCEEDED(hr);
}

void CMurasuAnjalTextService::_UninitThreadMgrEventSink()
{
    if (_dwThreadMgrEventSinkCookie != TF_INVALID_COOKIE)
    {
        ITfSource* pSource = NULL;
        if (SUCCEEDED(_pThreadMgr->QueryInterface(IID_ITfSource, (void**)&pSource)))
        {
            pSource->UnadviseSink(_dwThreadMgrEventSinkCookie);
            pSource->Release();
        }
        _dwThreadMgrEventSinkCookie = TF_INVALID_COOKIE;
    }
}

STDMETHODIMP CMurasuAnjalTextService::OnInitDocumentMgr(ITfDocumentMgr* pDocMgr)
{
    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::OnUninitDocumentMgr(ITfDocumentMgr* pDocMgr)
{
    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::OnSetFocus(ITfDocumentMgr* pDocMgrFocus, ITfDocumentMgr* pDocMgrPrevFocus)
{
    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::OnPushContext(ITfContext* pContext)
{
    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::OnPopContext(ITfContext* pContext)
{
    return S_OK;
}

// Key Event Sink
BOOL CMurasuAnjalTextService::_InitKeyEventSink()
{
    ITfKeystrokeMgr* pKeystrokeMgr = NULL;
    HRESULT hr = _pThreadMgr->QueryInterface(IID_ITfKeystrokeMgr, (void**)&pKeystrokeMgr);

	DebugOut(logTag, SUCCEEDED(hr) ? L"Got KeystrokeMgr" : L"FAILED to get KeystrokeMgr"); 

    if (SUCCEEDED(hr))
    {
        hr = pKeystrokeMgr->AdviseKeyEventSink(_tfClientId, (ITfKeyEventSink*)this, TRUE);

		DebugOut(logTag, SUCCEEDED(hr) ? L"AdviseKeyEventSink OK" : L"AdviseKeyEventSink FAILED"); 
        pKeystrokeMgr->Release();
    }

    return SUCCEEDED(hr);
}

void CMurasuAnjalTextService::_UninitKeyEventSink()
{
    ITfKeystrokeMgr* pKeystrokeMgr = NULL;
    if (SUCCEEDED(_pThreadMgr->QueryInterface(IID_ITfKeystrokeMgr, (void**)&pKeystrokeMgr)))
    {
        pKeystrokeMgr->UnadviseKeyEventSink(_tfClientId);
        pKeystrokeMgr->Release();
    }
}

STDMETHODIMP CMurasuAnjalTextService::OnSetFocus(BOOL fForeground)
{
    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::OnTestKeyDown(ITfContext* pContext, WPARAM wParam, LPARAM lParam, BOOL* pfEaten)
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

STDMETHODIMP CMurasuAnjalTextService::OnKeyDown(ITfContext* pContext, WPARAM wParam, LPARAM lParam, BOOL* pfEaten)
{
    DebugOut(logTag, L"=== OnKeyDown ===");
    DebugOut(logTag, L"  Context: %p", pContext);

    if (!pContext)
    {
        DebugOut(logTag, L"  ERROR: NULL Context!");
        *pfEaten = FALSE;
        return S_OK;
    }

    if (!pfEaten)
        return E_INVALIDARG;

    *pfEaten = FALSE;

    if (!_isKeyboardEnabled || !pContext)
        return S_OK;

    // ========== COMPREHENSIVE KEY LOGGING ==========

    DebugOut(logTag, L"=== OnKeyDown ===");
    DebugOut(logTag, L"  Virtual Key Code (wParam): 0x%02X (%d)", wParam, wParam);

    WCHAR keyName[256] = { 0 };
    GetKeyNameTextW((LONG)lParam, keyName, 256);
    DebugOut(logTag, L"  Key Name: %s", keyName);

    DebugOut(logTag, L"  lParam: 0x%08X", lParam);
    UINT scanCode = (lParam >> 16) & 0xFF;
    DebugOut(logTag, L"    Scan Code: 0x%02X (%d)", scanCode, scanCode);
    DebugOut(logTag, L"    Extended: %d", (lParam >> 24) & 0x01);
    DebugOut(logTag, L"    Alt Down: %d", (lParam >> 29) & 0x01);

    BYTE keyboardState[256] = { 0 };
    GetKeyboardState(keyboardState);

    WCHAR unicodeChars[10] = { 0 };
    int result = ToUnicode((UINT)wParam, scanCode, keyboardState, unicodeChars, 10, 0);

    if (result > 0)
    {
        DebugOut(logTag, L"  ToUnicode Result: '%s' (U+%04X)", unicodeChars, unicodeChars[0]);
        for (int i = 0; i < result; i++)
        {
            DebugOut(logTag, L"    Char[%d]: U+%04X ('%c')", i, unicodeChars[i], unicodeChars[i]);
        }
    }
    else if (result == 0)
    {
        DebugOut(logTag, L"  ToUnicode Result: No translation");
    }
    else
    {
        DebugOut(logTag, L"  ToUnicode Result: Dead key");
    }

    HKL hkl = GetKeyboardLayout(0);
    DebugOut(logTag, L"  Current HKL: 0x%08X", hkl);
    LANGID langId = LOWORD(hkl);
    DebugOut(logTag, L"  Language ID: 0x%04X (%d)", langId, langId);

    wchar_t tamilChar = _MapKeyToTamil(wParam);
    if (tamilChar != 0)
    {
        DebugOut(logTag, L"  Your Tamil99 Mapping: U+%04X ('%c')", tamilChar, tamilChar);

        // ✅ ADD DEFENSIVE CHECKS AND LOGGING
        DebugOut(logTag, L"  About to insert text...");

        // Check pContext validity
        if (!pContext)
        {
            DebugOut(logTag, L"  ERROR: pContext is NULL!");
            return S_OK;
        }

        DebugOut(logTag, L"  pContext valid: 0x%p", pContext);
        DebugOut(logTag, L"  _tfClientId: 0x%08X", _tfClientId);

        // Insert the Tamil character with error checking
        HRESULT hr = _InsertTextAtSelection(pContext, &tamilChar, 1);

        DebugOut(logTag, L"  _InsertTextAtSelection returned: 0x%08X", hr);

        if (SUCCEEDED(hr))
        {
            *pfEaten = TRUE;
            DebugOut(logTag, L"  Action: Successfully inserted Tamil char, ate key");
        }
        else
        {
            DebugOut(logTag, L"  ERROR: Failed to insert text, hr=0x%08X", hr);
        }
    }
    else
    {
        DebugOut(logTag, L"  Your Tamil99 Mapping: None (0x0000)");
        DebugOut(logTag, L"  Action: Not eating key");
    }

    DebugOut(logTag, L"=== End OnKeyDown ===");

    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::OnTestKeyUp(ITfContext* pContext, WPARAM wParam, LPARAM lParam, BOOL* pfEaten)
{
    if (!pfEaten)
        return E_INVALIDARG;

    *pfEaten = FALSE;
    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::OnKeyUp(ITfContext* pContext, WPARAM wParam, LPARAM lParam, BOOL* pfEaten)
{
    if (!pfEaten)
        return E_INVALIDARG;

    *pfEaten = FALSE;
    return S_OK;
}

STDMETHODIMP CMurasuAnjalTextService::OnPreservedKey(ITfContext* pContext, REFGUID rguid, BOOL* pfEaten)
{
    if (!pfEaten)
        return E_INVALIDARG;

    *pfEaten = FALSE;
    return S_OK;
}

// Helper: Insert text at current selection using edit session
HRESULT CMurasuAnjalTextService::_InsertTextAtSelection(ITfContext* pContext, const WCHAR* pchText, ULONG cchText)
{
    DebugOut(logTag, L"  _InsertTextAtSelection START");

    CEditSession* pEditSession = new CEditSession(pContext, pchText, cchText);
    if (pEditSession == NULL)
        return E_OUTOFMEMORY;

    DebugOut(logTag, L"    Calling RequestEditSession (ASYNC)...");

    HRESULT hr;
    HRESULT hrSession = S_OK;

    // ✅ Use ASYNC - safer for applications like Word
    hr = pContext->RequestEditSession(
        _tfClientId,
        pEditSession,
        TF_ES_ASYNCDONTCARE | TF_ES_READWRITE,  // ← Changed from TF_ES_SYNC
        &hrSession);

    DebugOut(logTag, L"    RequestEditSession: hr=0x%08X, hrSession=0x%08X", hr, hrSession);

    pEditSession->Release();
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
    static wchar_t buffer[2] = { 0 };
    buffer[0] = 0;

    // For now, return single character mapping
    // This method allows for future expansion to support conjuncts

    return buffer;
}
