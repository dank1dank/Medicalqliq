QMAKE_CXXFLAGS += -std=c++11

INCLUDEPATH += $$PWD

HEADERS += \
    $$PWD/qxlib/util/RapidJsonHelper.hpp \
    $$PWD/qxlib/db/QxDatabase.hpp \
    $$PWD/qxlib/dao/fhir/FhirResourceDao.hpp \
    $$PWD/qxlib/model/fhir/FhirResources.hpp \
    $$PWD/qxlib/dao/QxBaseDao.hpp \
    $$PWD/qxlib/model/fhir/FhirProcessor.hpp \
    $$PWD/qxlib/log/QxLog.hpp \
    $$PWD/qxlib/model/chat/QxMultiparty.hpp \
    $$PWD/qxlib/model/sip/QxSipContact.hpp \
    $$PWD/qxlib/dao/chat/QxMultipartyDao.hpp \
    $$PWD/qxlib/util/StringUtils.hpp \
    $$PWD/qxlib/dao/sip/QxSipContactDao.hpp \
    $$PWD/qxlib/model/QxQliqUser.hpp \
    $$PWD/qxlib/dao/QxQliqUserDao.hpp \
    $$PWD/qxlib/model/chat/QxQliqConnect.hpp \
    $$PWD/qxlib/model/QxSession.hpp \
    $$PWD/qxlib/log/web/QxWebLogRecordDao.hpp \
    $$PWD/qxlib/log/web/QxWebLogRecord.hpp \
    $$PWD/qxlib/log/sip/QxSipLogRecordDao.hpp \
    $$PWD/qxlib/log/sip/QxSipLogRecord.hpp \
    $$PWD/qxlib/log/QxDbLogRecordBaseDao.hpp \
    $$PWD/qxlib/log/cn/QxChangeNotificationLogDao.hpp \
    $$PWD/qxlib/util/QxCompression.hpp \
    $$PWD/qxlib/web/QxQliqWebError.hpp \
    $$PWD/qxlib/web/QxWebClient.hpp \
    $$PWD/qxlib/crypto/QxCrypto.hpp \
    $$PWD/qxlib/crypto/QxBase64.hpp \
    $$PWD/qxlib/dao/QxKeyValueDao.hpp \
    $$PWD/qxlib/platform/qt/QxPlatformQt.hpp \
    $$PWD/qxlib/crypto/QxMd5.hpp \
    $$PWD/qxlib/util/QxFilesystem.hpp \
    $$PWD/qxlib/platform/qt/QxPlatformQtHelpers.hpp \
    $$PWD/qxlib/web/emr/QxUploadToEmrWebService.cpp \
    $$PWD/qxlib/web/QxGetContactPubkeyWebService.hpp \
    $$PWD/qxlib/db/QxLogDatabase.hpp \
    $$PWD/qxlib/web/qliqstor/QxUploadToQliqStorWebService.hpp \
    $$PWD/qxlib/model/QxMediaFile.hpp \
    $$PWD/qxlib/controller/EncryptMediaFileTask.hpp \
    $$PWD/qxlib/dao/QxMediaFileDao.hpp \
    $$PWD/qxlib/dao/QxMediaFileUploadDao.hpp \
    $$PWD/qxlib/web/QxGetFileWebService.hpp \
    $$PWD/qxlib/dao/qliqstor/QxMediaFileUploadEventDao.hpp \
    $$PWD/qxlib/util/QxSpan.hpp \
    $$PWD/qxlib/controller/QxMediaFileManager.hpp \
    $$PWD/qxlib/util/QxAssert.hpp \
    $$PWD/qxlib/util/QxThreadUtil.hpp \
    $$PWD/qxlib/controller/QxApplication.hpp \
    $$PWD/qxlib/controller/qliqstor/QxQliqStorClient.hpp \
    $$PWD/qxlib/util/QxStdioUtil.hpp \
    $$PWD/qxlib/dao/chat/QxConversationDao.hpp \
    $$PWD/qxlib/dao/chat/QxCareChannelDao.hpp \
    $$PWD/qxlib/dao/fhir/QxFhirEncounterDao.hpp \
    $$PWD/qxlib/dao/QxChangeNotificationDao.hpp \
    $$PWD/qxlib/controller/QxChangeNotificationProcessor.hpp \
    $$PWD/qxlib/model/QxSessionListener.hpp \
    $$PWD/qxlib/util/QxTimer.hpp \
    $$PWD/qxlib/util/QxNetworkMonitor.hpp \
    $$PWD/qxlib/web/QxGetPresenceStatusWebService.hpp \
    $$PWD/qxlib/model/QxContactsModel.hpp \
    $$PWD/qxlib/model/chat/QxChatMessage.hpp \
    $$PWD/qxlib/model/QxContactsListener.hpp \
    $$PWD/qxlib/util/QxDestructionNotifier.hpp \
    $$PWD/qxlib/dao/web/QxWebRequestDao.hpp \
    $$PWD/qxlib/web/QxDatabaseWebClient.hpp \
    $$PWD/qxlib/db/QxDatabaseUtil.hpp \
    $$PWD/qxlib/web/fax/QxUploadToFaxWebService.hpp \
    $$PWD/qxlib/model/fax/QxFaxContact.hpp \
    $$PWD/qxlib/dao/fax/QxFaxContactDao.hpp \
    $$PWD/qxlib/web/fax/QxGetFaxContactsWebService.hpp \
    $$PWD/qxlib/web/fax/QxModifyFaxContactsWebService.hpp \
    $$PWD/qxlib/util/QxUuid.hpp \
    $$PWD/qxlib/util/QxTerminateHandler.hpp \
    $$PWD/qxlib/dao/chat/QxChatMessageDao.hpp \
    $$PWD/qxlib/controller/qliqstor/QxExportConversation.hpp \
    $$PWD/qxlib/model/QxQliqStor.hpp \
    $$PWD/qxlib/dao/qliqstor/QxQliqStorDao.hpp \
    $$PWD/qxlib/db/QxDatabaseBenchmark.hpp \
    $$PWD/qxlib/util/QxSettings.hpp \
    $$PWD/qxlib/web/QxGetDeviceStatusWebService.hpp \
    $$PWD/qxlib/log/push/QxPushNotificationLogRecordDao.hpp \
    $$PWD/qxlib/util/QxRowDataObserver.hpp

SOURCES += \
    $$PWD/qxlib/util/RapidJsonHelper.cpp \
    $$PWD/qxlib/db/QxDatabase.cpp \
    $$PWD/qxlib/dao/fhir/FhirResourceDao.cpp \
    $$PWD/qxlib/model/fhir/FhirResources.cpp \
    $$PWD/qxlib/model/fhir/FhirProcessor.cpp \
    $$PWD/qxlib/log/QxLog.cpp \
    $$PWD/qxlib/model/chat/QxMultiparty.cpp \
    $$PWD/qxlib/model/sip/QxSipContact.cpp \
    $$PWD/qxlib/dao/chat/QxMultipartyDao.cpp \
    $$PWD/qxlib/util/StringUtils.cpp \
    $$PWD/qxlib/dao/sip/QxSipContactDao.cpp \
    $$PWD/qxlib/log/sip/QxSipLogRecord.cpp \
    $$PWD/qxlib/log/sip/QxSipLogRecordDao.cpp \
    $$PWD/qxlib/model/QxQliqUser.cpp \
    $$PWD/qxlib/dao/QxQliqUserDao.cpp \
    $$PWD/qxlib/model/chat/QxQliqConnect.cpp \
    $$PWD/qxlib/model/QxSession.cpp \
    $$PWD/qxlib/log/web/QxWebLogRecordDao.cpp \
    $$PWD/qxlib/log/web/QxWebLogRecord.cpp \
    $$PWD/qxlib/log/cn/QxChangeNotificationLogDao.cpp \
    $$PWD/qxlib/util/QxCompression.cpp \
    $$PWD/qxlib/web/QxQliqWebError.cpp \
    $$PWD/qxlib/web/QxWebClient.cpp \
    $$PWD/qxlib/crypto/QxCrypto.cpp \
    $$PWD/qxlib/crypto/QxBase64.cpp \
    $$PWD/qxlib/dao/QxKeyValueDao.cpp \
    $$PWD/qxlib/platform/qt/QxPlatformQt.cpp \
    $$PWD/qxlib/crypto/QxMd5.cpp \
    $$PWD/qxlib/util/QxFilesystem.cpp \
    $$PWD/qxlib/platform/qt/QxPlatformQtHelpers.cpp \
    $$PWD/qxlib/web/emr/QxUploadToEmrWebService.cpp \
    $$PWD/qxlib/web/QxGetContactPubkeyWebService.cpp \
    $$PWD/qxlib/db/QxLogDatabase.cpp \
    $$PWD/deps/libb64/src/encode.cpp \
    $$PWD/qxlib/web/qliqstor/QxUploadToQliqStorWebService.cpp \
    $$PWD/qxlib/model/QxMediaFile.cpp \
    $$PWD/qxlib/controller/EncryptMediaFileTask.cpp \
    $$PWD/qxlib/dao/QxMediaFileDao.cpp \
    $$PWD/qxlib/dao/QxMediaFileUploadDao.cpp \
    $$PWD/qxlib/web/QxGetFileWebService.cpp \
    $$PWD/qxlib/dao/qliqstor/QxMediaFileUploadEventDao.cpp \
    $$PWD/qxlib/util/QxSpan.cpp \
    $$PWD/qxlib/controller/QxMediaFileManager.cpp \
    $$PWD/qxlib/util/compress/zip/ioapi_c.c \
    $$PWD/qxlib/util/QxThreadUtil.cpp \
    $$PWD/qxlib/controller/QxApplication.cpp \
    $$PWD/qxlib/controller/qliqstor/QxQliqStorClient.cpp \
    $$PWD/qxlib/util/QxStdioUtil.cpp \
    $$PWD/qxlib/dao/chat/QxConversationDao.cpp \
    $$PWD/qxlib/dao/chat/QxCareChannelDao.cpp \
    $$PWD/qxlib/dao/fhir/QxFhirEncounterDao.cpp \
    $$PWD/qxlib/dao/QxChangeNotificationDao.cpp \
    $$PWD/qxlib/controller/QxChangeNotificationProcessor.cpp \
    $$PWD/qxlib/util/QxTimer.cpp \
    $$PWD/qxlib/util/QxNetworkMonitor.cpp \
    $$PWD/qxlib/web/QxGetPresenceStatusWebService.cpp \
    $$PWD/qxlib/model/QxContactsModel.cpp \
    $$PWD/qxlib/model/chat/QxChatMessage.cpp \
    $$PWD/qxlib/util/QxDestructionNotifier.cpp \
    $$PWD/qxlib/dao/web/QxWebRequestDao.cpp \
    $$PWD/qxlib/web/QxDatabaseWebClient.cpp \
    $$PWD/qxlib/db/QxDatabaseUtil.cpp \
    $$PWD/qxlib/web/fax/QxUploadToFaxWebService.cpp \
    $$PWD/qxlib/model/fax/QxFaxContact.cpp \
    $$PWD/qxlib/dao/fax/QxFaxContactDao.cpp \
    $$PWD/qxlib/web/fax/QxGetFaxContactsWebService.cpp \
    $$PWD/qxlib/web/fax/QxModifyFaxContactsWebService.cpp \
    $$PWD/qxlib/util/QxUuid.cpp \
    $$PWD/qxlib/util/QxTerminateHandler.cpp \
    $$PWD/qxlib/dao/QxBaseDao.cpp \
    $$PWD/qxlib/dao/chat/QxChatMessageDao.cpp \
    $$PWD/qxlib/controller/qliqstor/QxExportConversation.cpp \
    $$PWD/qxlib/model/QxQliqStor.cpp \
    $$PWD/qxlib/dao/qliqstor/QxQliqStorDao.cpp \
    $$PWD/qxlib/db/QxDatabaseBenchmark.cpp \
    $$PWD/qxlib/util/QxSettings.cpp \
    $$PWD/qxlib/web/QxGetDeviceStatusWebService.cpp \
    $$PWD/qxlib/log/push/QxPushNotificationLogRecordDao.cpp \
    $$PWD/qxlib/util/QxRowDataObserver.cpp \
    $$PWD/qxlib/model/sip/QxSipUtil.cpp

QLIQ_DESKTOP {

HEADERS += \
    # OnCall
    $$PWD/qxlib/web/oncall/QxGetOnCallGroupUpdatesWebService.hpp \
    $$PWD/qxlib/dao/oncall/QxOnCallGroupsDao.hpp \
    # EMR
    $$PWD/qxlib/web/QxSearchPatientsWebService.hpp \
    $$PWD/qxlib/controller/qliqstor/QxUploadToQliqStorTask.hpp

SOURCES += \
    # OnCall
    $$PWD/qxlib/web/oncall/QxGetOnCallGroupUpdatesWebService.cpp \
    $$PWD/qxlib/dao/oncall/QxOnCallGroupsDao.cpp \
    # EMR
    $$PWD/qxlib/web/QxSearchPatientsWebService.cpp \
    $$PWD/qxlib/controller/qliqstor/QxUploadToQliqStorTask.cpp

} # QLIQ_DESKTOP

qxl_has_sip {
    # If has SIP functionality
    DEFINES += QXL_HAS_SIP

    HEADERS += \
        $$PWD/qxlib/model/sip/QxSip.hpp \
        $$PWD/qxlib/log/sip/QxSipLogModule.hpp \
        $$PWD/qxlib/model/sip/QxSipModules.hpp \
        $$PWD/qxlib/model/sip/QxSipUtil.hpp

    SOURCES += \
        $$PWD/qxlib/model/sip/QxSip.cpp \
        $$PWD/qxlib/log/sip/QxSipLogModule.cpp \
        $$PWD/qxlib/model/sip/QxSipModules.cpp
}

qxl_feature_assembla {
    DEFINES += QXL_FEATURE_ASSEMBLA

    HEADERS += \
        $$PWD/qxlib/debug/QxAssemblaConfig.hpp \
        $$PWD/qxlib/web/assembla/QxAssemblaBaseWebService.hpp \
#        $$PWD/qxlib/web/assembla/QxCreateTicketAssemblaWebService.hpp \
        $$PWD/qxlib/web/assembla/QxAssemblaGetUsersWebService.hpp \
        $$PWD/qxlib/web/assembla/QxAssemblaTicketsMyActiveWebService.hpp \
        $$PWD/qxlib/web/assembla/QxAssemblaTicketsWebService.hpp \
        $$PWD/qxlib/web/assembla/QxAssemblaDocumentsWebService.hpp

    SOURCES += \
        $$PWD/qxlib/debug/QxAssemblaConfig.cpp \
        $$PWD/qxlib/web/assembla/QxAssemblaBaseWebService.cpp \
#        $$PWD/qxlib/web/assembla/QxCreateTicketAssemblaWebService.cpp \
        $$PWD/qxlib/web/assembla/QxAssemblaGetUsersWebService.cpp \
        $$PWD/qxlib/web/assembla/QxAssemblaTicketsMyActiveWebService.cpp \
        $$PWD/qxlib/web/assembla/QxAssemblaTicketsWebService.cpp \
        $$PWD/qxlib/web/assembla/QxAssemblaDocumentsWebService.cpp
}

win32 {
    HEADERS += $$PWD/qxlib/util/strptime.h \
        $$PWD/qxlib/platform/windows/QxPlatformWindowsHelpers.hpp

    SOURCES += $$PWD/qxlib/util/strptime.c \
        $$PWD/qxlib/platform/windows/QxPlatformWindowsHelpers.cpp
} # win32

# qliqStor webapp does not link with zip libs and does not include LogArchive
!QLIQ_STOR_WEB_SERVICE {
HEADERS += \
    $$PWD/qxlib/log/QxLogArchive.hpp

SOURCES += \
    $$PWD/qxlib/log/QxLogArchive.cpp
}

INCLUDEPATH += $$PWD/deps
INCLUDEPATH += $$PWD/deps/Optional

#DEFINES += RAPIDJSON_HAS_STDSTRING
INCLUDEPATH += $$PWD/deps/rapidjson/include

include($$PWD/deps/libb64/libb64.pri)
HEADERS += \
    $$PWD/deps/json11/json11.hpp

SOURCES += \
    $$PWD/deps/json11/json11.cpp

DEFINES += QXL_DEVICE_PC QXL_HAS_QT

macx {
    DEFINES += QXL_OS_MAC
}
win32 {
    DEFINES += QXL_OS_WIN
}
linux {
    DEFINES += QXL_OS_LINUX
}
# also possible: QXL_OS_IOS, QXL_OS_ANDROID
debug {
    DEFINES += QX_DEBUG
}

LIBS += -lz

RESOURCES += \
    $$PWD/data/sql/logdb/logdb_sql.qrc

# INCLUDEPATH += $$PWD/deps/zstd/include
# LIBS += -L$$PWD/deps/zstd/lib -lzstd
#     $$PWD/qxlib/util/QxZstd.hpp
#    $$PWD/qxlib/util/QxZstd.cpp

include($$PWD/deps/SQLiteCpp/SQLiteCpp.pri)
