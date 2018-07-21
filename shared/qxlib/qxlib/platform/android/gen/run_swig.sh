#!/bin/bash
OUTDIR=java

mkdir -p $OUTDIR
swig -c++ -java -package com.qliqsoft.qx.web -outdir $OUTDIR -I../../../.. ../web.i

# After generating code the qxwebJNI.java must be edited, to change memory ownership (from false to true) for all above ResultCallback, like this:
#
# public static void SwigDirector_GetContactPubKeyWebService_ResultCallback_run(GetContactPubKeyWebService.ResultCallback jself, long error, String pubKey) {
#    jself.run(new QliqWebError(error, >>> true <<<), pubKey);
#  }
#
# This is because we want Java to keep ownership of it so the data can live longer then C++ side callback.
# This is required to post data to UI thread from the Java callback which is background OkHttp thread.
sed -i 's/, false)/, true)/g' $OUTDIR/qxwebJNI.java
