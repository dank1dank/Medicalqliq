#-------------------------------------------------
#
# This is a test project, used only to verify if qxlib source compile correctly
#
#-------------------------------------------------

QT       += core
QT       -= core gui
QMAKE_CXXFLAGS += -std=c++11

TARGET = qxlib 
TEMPLATE = lib

include(qxlib.pri)

DEFINES -= QXL_HAS_QT

HEADERS -= \
    $$PWD/qxlib/platform/qt/QxPlatformQt.hpp \
    $$PWD/qxlib/platform/qt/QxPlatformQtHelpers.hpp

SOURCES -= \
    $$PWD/qxlib/platform/qt/QxPlatformQt.cpp \
    $$PWD/qxlib/platform/qt/QxPlatformQtHelpers.cpp

#SOURCES += \
#    qxlib/platform/android/QxPlatformAndroid.cpp
#
#INCLUDEPATH += /storage/android/sdk/ndk-bundle/platforms/android-14/arch-x86/usr/include
