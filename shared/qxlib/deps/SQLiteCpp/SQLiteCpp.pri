SOURCES += $$PWD/src/Column.cpp \
	$$PWD/src/Statement.cpp \
        $$PWD/src/Transaction.cpp \
    $$PWD/src/SQLiteDatabase.cpp

HEADERS += $$PWD/include/SQLiteCpp/Column.h \
	$$PWD/include/SQLiteCpp/Statement.h \
	$$PWD/include/SQLiteCpp/Transaction.h \
	$$PWD/include/SQLiteCpp/Assertion.h \
	$$PWD/include/SQLiteCpp/Exception.h \
	$$PWD/include/SQLiteCpp/SQLiteCpp.h \
    $$PWD/include/SQLiteCpp/SQLiteDatabase.h

INCLUDEPATH += $$PWD/include

# SqlCipher Qt plugin statically linked
# That is to make sure Qt code and qxlib code
# use single (the same) instance of sqlite code in memory
DEFINES += STATIC_QSQLCIPHER_PLUGIN
INCLUDEPATH += $$PWD/../../../../lib/sqlcipher/include
win32 {
    LIBS += -L$$PWD/../../../../lib/sqlcipher/lib
}
macx {
    LIBS += -L$$PWD/../../../../lib/sqlcipher/lib/mac
}
LIBS += -lsqlcipher -lqsqlcipher
