%module(directors="1") qxweb
%{
/* Includes the header in the wrapper code */
#include "qxlib/web/QxQliqWebError.hpp"
#include "qxlib/web/QxWebClient.hpp"
#include "qxlib/web/QxGetContactPubkeyWebService.hpp"
#include "qxlib/web/QxGetFileWebService.hpp"
#include "qxlib/dao/QxMediaFileDao.hpp"
#include "qxlib/dao/QxMediaFileUploadDao.hpp"
#include "qxlib/dao/qliqstor/QxMediaFileUploadEventDao.hpp"
#include "qxlib/dao/qliqstor/QxQliqStorDao.hpp"
#include "qxlib/controller/QxMediaFileManager.hpp"
#include "qxlib/model/fhir/FhirResources.hpp"
#include "qxlib/web/QxSearchPatientsWebService.hpp"
#include "qxlib/web/emr/QxUploadToEmrWebService.hpp"
#include "qxlib/controller/qliqstor/QxUploadToQliqStorTask.hpp"
#include "qxlib/controller/qliqstor/QxQliqStorClient.hpp"
// Care Channels
#include "qxlib/dao/chat/QxCareChannelDao.hpp"
#include "qxlib/dao/fhir/QxFhirEncounterDao.hpp"
#include "qxlib/model/fhir/FhirProcessor.hpp"
// Chat
#include "qxlib/model/sip/QxSipContact.hpp"
#include "qxlib/model/chat/QxMultiparty.hpp"
#include "qxlib/dao/chat/QxMultipartyDao.hpp"
// Change Notifications
#include "qxlib/controller/QxChangeNotificationProcessor.hpp"
#include "qxlib/util/QxNetworkMonitor.hpp"
#include "qxlib/model/QxSession.hpp"
// Fax
#include "qxlib/model/fax/QxFaxContact.hpp"
#include "qxlib/dao/fax/QxFaxContactDao.hpp"
#include "qxlib/web/fax/QxGetFaxContactsWebService.hpp"
#include "qxlib/web/fax/QxModifyFaxContactsWebService.hpp"
%}

%include "std_vector.i"
%include "std_string_allow_null.i"

%ignore SQLite::Database;
%ignore qx::SQLite::Database;
%ignore QxBaseDao;

// Parse the header file to generate wrappers
%include "qxlib/web/QxQliqWebError.hpp"
// %ignore qx::web::BaseWebService;
%include "qxlib/web/QxWebClient.hpp"

%feature("director") qx::MediaFileUploadSubscriber;
%include "qxlib/model/QxMediaFile.hpp"
%include "qxlib/dao/QxMediaFileDao.hpp"

%feature("director") qx::MediaFileManager::ResultCallback;
%include "qxlib/controller/QxMediaFileManager.hpp"

namespace std {
   %template(MediaFileUploadVector) vector<qx::MediaFileUpload>;
};
%include "qxlib/dao/QxMediaFileUploadDao.hpp"

namespace std {
   %template(MediaFileUploadEventVector) vector<qx::MediaFileUploadEvent>;
};
%include "qxlib/dao/qliqstor/QxMediaFileUploadEventDao.hpp"
%include "qxlib/dao/qliqstor/QxQliqStorDao.hpp"

// http://stackoverflow.com/questions/8168517/generating-java-interface-with-swig
// https://github.com/swig/swig/tree/master/Examples/java/callback
%feature("director") qx::web::GetContactPubKeyWebService::ResultCallback;

%template(PatientVector) std::vector<fhir::Patient>;
%template(StringVector) std::vector<std::string>;

%include "qxlib/web/QxGetContactPubkeyWebService.hpp"

%feature("director") qx::web::GetFileWebService::ResultCallback;
%include "qxlib/web/QxGetFileWebService.hpp"

%include "qxlib/model/fhir/FhirResources.hpp"

%feature("director") qx::web::SearchPatientsWebService::ResultCallback;
%include "qxlib/web/QxSearchPatientsWebService.hpp"

%feature("director") qx::web::UploadToQliqStorWebService::ResultCallback;
%include "qxlib/web/qliqstor/QxUploadToQliqStorWebService.hpp"

%feature("director") qx::UploadToQliqStorTask::ResultCallback;
%include "qxlib/controller/qliqstor/QxExportConversation.hpp"
%include "qxlib/controller/qliqstor/QxUploadToQliqStorTask.hpp"

%feature("director") qx::web::UploadToEmrWebService::ResultCallback;
%include "qxlib/web/emr/QxUploadToEmrWebService.hpp"

//%feature("director") qx::UploadToEmrTask::ResultCallback;
//%include "qxlib/controller/emr/QxUploadToEmrTask.hpp"

%template(QliqStorPerGroupVector) std::vector<qx::QliqStorClient::QliqStorPerGroup>;
// Ignore overloads without default value for db argument
%rename ("$ignore", fullname=1) qx::QliqStorClient::qliqStors(SQLite::Database&);
%rename ("$ignore", fullname=1) qx::QliqStorClient::defaultQliqStor(SQLite::Database&);
%rename ("$ignore", fullname=1) qx::QliqStorClient::shouldShowQliqStorSelectionDialog(SQLite::Database&);
%rename ("$ignore", fullname=1) qx::QliqStorClient::setDefaultQliqStor(const QliqStorPerGroup&, SQLite::Database&);
%include "qxlib/controller/qliqstor/QxQliqStorClient.hpp"

// Care Channels
%include "qxlib/dao/chat/QxCareChannelDao.hpp"
%include "qxlib/model/fhir/FhirProcessor.hpp"
%include "qxlib/dao/fhir/QxFhirEncounterDao.hpp"

// Chat
%include "qxlib/model/sip/QxSipContact.hpp"
%template(MultipartyParticipantVector) std::vector<qx::Multiparty::Participant>;
%include "qxlib/model/chat/QxMultiparty.hpp"
%include "qxlib/dao/chat/QxMultipartyDao.hpp"

// Change Notifications
%feature("director") qx::ChangeNotificationListener;
%include "qxlib/controller/QxChangeNotificationProcessor.hpp"
%include "qxlib/util/QxNetworkMonitor.hpp"
%include "qxlib/model/QxSession.hpp"

// Fax
%include "qxlib/model/fax/QxFaxContact.hpp"
%template(FaxContactVector) std::vector<qx::FaxContact>;
// Ignore overloads without default value for db argument
%rename ("$ignore", fullname=1) qx::FaxContactDao::search(const std::string&, int, int, SQLite::Database&);
%rename ("$ignore", fullname=1) qx::FaxContactDao::search(const std::string&, int);
%rename ("$ignore", fullname=1) qx::FaxContactDao::search(const std::string&);
%include "qxlib/dao/fax/QxFaxContactDao.hpp"
%feature("director") qx::web::GetFaxContactsWebService::ResultCallback;
%include "qxlib/web/fax/QxGetFaxContactsWebService.hpp"
%feature("director") qx::web::ModifyFaxContactsWebService::ResultCallback;
%include "qxlib/web/fax/QxModifyFaxContactsWebService.hpp"

/*
 After generating code the qxwebJNI.java must be edited, to change memory ownership (from false to true) for all above ResultCallback, like this:

public static void SwigDirector_GetContactPubKeyWebService_ResultCallback_run(GetContactPubKeyWebService.ResultCallback jself, long error, String pubKey) {
    jself.run(new QliqWebError(error, true), pubKey);
  }
  public static void SwigDirector_SearchPatientsWebService_ResultCallback_run(SearchPatientsWebService.ResultCallback jself, long error, long result) {
    jself.run((error == 0) ? null : new QliqWebError(error, true), (result == 0) ? null : new SearchPatientsWebService.Result(result, true));
  }
  public static void SwigDirector_UploadToEmrWebService_ResultCallback_run(UploadToEmrWebService.ResultCallback jself, long error) {
    jself.run((error == 0) ? null : new QliqWebError(error, true));
  }

 This is because we want Java to keep ownership of it so the data can live longer then C++ side callback.
 This is required to post data to UI thread from the Java callback which is background OkHttp thread.
*/
