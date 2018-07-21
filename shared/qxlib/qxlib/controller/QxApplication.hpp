#ifndef QXAPPLICATION_HPP
#define QXAPPLICATION_HPP

namespace qx {

// Common (core) code for all qliq applications
class Application
{
public:
    Application();

    void onDatabaseOpened();
    void onLoggedOut();
};

} // qx

#endif // QXAPPLICATION_HPP
