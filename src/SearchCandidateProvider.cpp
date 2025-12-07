#include "../include/MurasuAnjalCore.h"
#include "../include/SearchCandidateProvider.h"
#include "../include/Debug.h"

CSearchCandidateProvider::CSearchCandidateProvider()
{
    _refCount = 1;
}

CSearchCandidateProvider::~CSearchCandidateProvider()
{
}

STDMETHODIMP CSearchCandidateProvider::QueryInterface(REFIID riid, void **ppvObj)
{
    if (!ppvObj)
        return E_POINTER;

    *ppvObj = NULL;

    if (IsEqualIID(riid, IID_IUnknown) || 
        IsEqualIID(riid, __uuidof(ITfFnSearchCandidateProvider)))
    {
        *ppvObj = (ITfFnSearchCandidateProvider*)this;
    }
    else if (IsEqualIID(riid, IID_ITfFunction))
    {
        *ppvObj = (ITfFunction*)this;
    }

    if (*ppvObj)
    {
        AddRef();
        return S_OK;
    }

    return E_NOINTERFACE;
}

STDMETHODIMP_(ULONG) CSearchCandidateProvider::AddRef()
{
    return InterlockedIncrement(&_refCount);
}

STDMETHODIMP_(ULONG) CSearchCandidateProvider::Release()
{
    ULONG ref = InterlockedDecrement(&_refCount);
    if (ref == 0)
        delete this;
    return ref;
}

STDMETHODIMP CSearchCandidateProvider::GetDisplayName(BSTR *pbstrName)
{
    if (!pbstrName)
        return E_INVALIDARG;

    *pbstrName = SysAllocString(L"Murasu Anjal Tamil99");
    return S_OK;
}

STDMETHODIMP CSearchCandidateProvider::GetSearchCandidates(
    BSTR bstrQuery, 
    BSTR bstrApplicationID, 
    ITfCandidateList **pplist)
{
    DebugOut(logTag, L"GetSearchCandidates called! Query: %s", bstrQuery);
    
    // For now, return empty list - Search will still work
    // because your OnKeyDown() will handle the actual text insertion
    *pplist = NULL;
    
    return S_OK;
}

STDMETHODIMP CSearchCandidateProvider::SetResult(
    BSTR bstrQuery, 
    BSTR bstrApplicationID, 
    BSTR bstrResult)
{
    // Not used for simple IMEs
    return E_NOTIMPL;
}