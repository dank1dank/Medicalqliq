#include "QxUuid.hpp"
#ifdef QXL_HAS_QT
#include <QUuid>
#elif QXL_OS_IOS
extern "C" char *alloc_uuid_for_qxlib();
#else
#include <fstream>
#endif

namespace qx {

std::string Uuid::generate()
{
#ifdef QXL_HAS_QT
    QString uuid = QUuid::createUuid().toString();
    // Remove the {} braces
    return uuid.mid(1, uuid.length() - 2).toStdString();
#elif QXL_OS_IOS
    char *raw = alloc_uuid_for_qxlib();
    std::string uuid(raw);
    free(raw);
    return uuid;
#else
    // https://stackoverflow.com/questions/11888055/include-uuid-h-into-android-ndk-project
    std::ifstream in("/proc/sys/kernel/random/uuid");
    std::string s((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    return s;
#endif
}

} // qx
