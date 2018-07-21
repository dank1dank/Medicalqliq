#include "QxThreadUtil.hpp"
#ifdef Q_OS_WIN
#include <qt_windows.h>

namespace {

void setCurrentThreadNameWindows(const QString& name)
{
    // The SetThreadDescription API was brought in version 1607 of Windows 10.
    typedef HRESULT(WINAPI* SetThreadDescription)(HANDLE hThread, PCWSTR lpThreadDescription);

    HMODULE kernel32 = GetModuleHandleA("kernel32.dll");
    auto func = reinterpret_cast<SetThreadDescription>(GetProcAddress(kernel32, "SetThreadDescription"));
    if (func) {
        func(GetCurrentThread(), reinterpret_cast<PCWSTR>(name.utf16()));
    }
}

} // namespace

#endif // Q_OS_WIN

namespace qx {

void ThreadUtil::setCurrentThreadName(const QString &name)
{
#ifdef Q_OS_WIN
    setCurrentThreadNameWindows(name);
#endif
}

} // namespace qx
