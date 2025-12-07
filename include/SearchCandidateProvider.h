#pragma once
#include <windows.h>
#include <msctf.h>
#include <ctffunc.h> 

class CSearchCandidateProvider : public ITfFnSearchCandidateProvider
{
public:
    CSearchCandidateProvider();
    ~CSearchCandidateProvider();

    // IUnknown
    STDMETHODIMP QueryInterface(REFIID riid, void **ppvObj);
    STDMETHODIMP_(ULONG) AddRef();
    STDMETHODIMP_(ULONG) Release();

    // ITfFunction
    STDMETHODIMP GetDisplayName(BSTR *pbstrName);

    // ITfFnSearchCandidateProvider
    STDMETHODIMP GetSearchCandidates(BSTR bstrQuery, BSTR bstrApplicationID, ITfCandidateList **pplist);
    STDMETHODIMP SetResult(BSTR bstrQuery, BSTR bstrApplicationID, BSTR bstrResult);

private:
    LONG _refCount;
};
