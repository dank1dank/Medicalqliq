# Common environment for simulator and device

BUILDS="device sim"
#BUILDS="device" 
#BUILDS="sim"

export PROJECTS_DIR=${HOME}/projects
export QLIQPROJECT_DIR=${HOME}/qliqiphone
export PJPROJECT_DIR=${PROJECTS_DIR}/pjproject-qliq
DEVELOPER=`xcode-select -print-path`
export BUILD_TOOLS="${DEVELOPER}"
SDKVERSION=`xcrun -sdk iphoneos --show-sdk-version`

export PJCONFIG_FILE=${PJPROJECT_DIR}/pjlib/include/pj/config_site.h
echo "#define PJ_GETHOSTIP_DISABLE_LOCAL_RESOLUTION 1" > ${PJCONFIG_FILE}
echo "#define PJSIP_TRANSPORT_IDLE_TIME 720" >> ${PJCONFIG_FILE}
echo "#define PJSIP_MAX_PKT_LEN 32768" >> ${PJCONFIG_FILE}
echo "#define PJSIP_TLS_KEEP_ALIVE_INTERVAL 0" >> ${PJCONFIG_FILE}
echo "#define PJ_CONFIG_IPHONE 1" >> ${PJCONFIG_FILE}
echo "#define PJSIP_HAS_TLS_TRANSPORT 1" >> ${PJCONFIG_FILE}
echo "#define PJ_HAS_SSL_SOCK 1" >> ${PJCONFIG_FILE}
echo "#define PJ_HAS_IPV6 1" >> ${PJCONFIG_FILE}
echo "#include <pj/config_site_sample.h>" >> ${PJCONFIG_FILE}
cd ${PJPROJECT_DIR}
mkdir -p ${PJPROJECT_DIR}/build

export OPENSSL=${QLIQPROJECT_DIR}/shared/openssl
export TARGET="apple-darwin_ios"
export TARGET2="arm-apple-darwin10"
export PJSIPLIBS="libg7221codec libgsmcodec libilbccodec libpj libpjlib-util libpjmedia libpjmedia-audiodev libpjmedia-codec libpjmedia-videodev libpjnath libpjsip libpjsip-simple libpjsip-ua libpjsua libpjsua2 libresample libspeex libsrtp"

for BUILD in ${BUILDS}
do

  if [ "${BUILD}" == "device" ];
  then

    #Build configuration for device (7, 64)
    export IPHONESDK="iPhoneOS${SDKVERSION}.sdk"
    export DEVPATH=${DEVELOPER}/Platforms/iPhoneOS.platform/Developer
    #export CC=`xcrun -find -sdk iphoneos clang`
    export CFLAGS="-g -Wno-unused-label -I${OPENSSL}/include"
    export LDFLAGS="-L${OPENSSL}/lib"

    # Build for device (arm 7)
    find . -name ".*.depend" -exec rm {} \; -print
    find . -name ".*.o" -exec rm {} \; -print
    export ARCH='-arch armv7'
    export DESTDIR="${PJPROJECT_DIR}/build"
    mkdir -p ${DESTDIR}
    echo "-----------------------  Configuring for ARM 7 -------------------------"
    ./configure-iphone --prefix='' --with-ssl=${OPENSSL}
    echo "----------------------  Making for ARM 7 -----------------------------"
    make dep && make clean && make && make install

    # Build for device (arm 7s)
    find . -name ".*.depend" -exec rm {} \; -print
    find . -name ".*.o" -exec rm {} \; -print
    export ARCH='-arch armv7s'
    echo "-----------------------  Configuring for ARM 7S -------------------------"
    ./configure-iphone --prefix='' --with-ssl=${OPENSSL}
    echo "----------------------  Making for ARM 7S -----------------------------"
    make dep && make clean && make && make install

    # Build for device (arm 64)
    find . -name ".*.depend" -exec rm {} \; -print
    find . -name ".*.o" -exec rm {} \; -print
    export ARCH='-arch arm64'
    echo "-----------------------  Configuring for ARM 64 -------------------------"
    ./configure-iphone --prefix='' --with-ssl=${OPENSSL}
    echo "----------------------  Making for ARM 64 -----------------------------"
    make dep && make clean && make && make install

    export LIBDIR="${DESTDIR}/lib"
    export INCDIR="${DESTDIR}/include"

    export DESTDIR=${QLIQPROJECT_DIR}/shared/pjsip/pjsip-iphoneos

    # Merging Libraries using lipo
    for prefix in ${PJSIPLIBS}
    do
      echo "lipo -create ${prefix}"
      lipo -create ${LIBDIR}/${prefix}-armv7-${TARGET}.a ${LIBDIR}/${prefix}-armv7s-${TARGET}.a ${LIBDIR}/${prefix}-arm64-${TARGET}.a -output ${DESTDIR}/lib/${prefix}-${TARGET2}.a
      echo "rm ${prefix}"
      rm ${LIBDIR}/${prefix}-armv7-${TARGET}.a ${LIBDIR}/${prefix}-armv7s-${TARGET}.a ${LIBDIR}/${prefix}-arm64-${TARGET}.a
    done

    mkdir -p ${DESTDIR}/include
    echo "Copying Include files to ${DESTDIR}/include"
    cp -R ${INCDIR} ${DESTDIR}

  fi

  if [ "${BUILD}" == "sim" ];
  then

    #Build configuration for simulator (i386, x86_64)
    export IPHONESDK="iPhoneSimulator.sdk"
    export CFLAGS="-g -miphoneos-version-min=6.0 -I${OPENSSL}/include"
    export LDFLAGS="-miphoneos-version-min=6.0  -L${OPENSSL}/lib"
    export DEVPATH=${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer
    export PATH=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin:/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH

    # Build for simulator i386
    find . -name ".*.depend" -exec rm {} \; -print
    find . -name ".*.o" -exec rm {} \; -print
    export ARCH='-arch i386'
    find . -name ".*.depend" -exec rm {} \; -print
    # export CC=`xcrun -find -sdk iphoneos gcc`
    export DESTDIR="${PJPROJECT_DIR}/build"
    mkdir -p ${DESTDIR}
    echo "----------------- Configuring for iPhone Simulator i386 --------------------"
    ./configure-iphone --prefix='' --with-ssl=${OPENSSL}
    echo "----------------- Making for iPhone Simulator  i386 ------------------------"
    make dep && make clean && make && make install

    # Build for simulator x86_64
    find . -name ".*.depend" -exec rm {} \; -print
    find . -name ".*.o" -exec rm {} \; -print
    export ARCH='-arch x86_64'
    find . -name ".*.depend" -exec rm {} \; -print
    # export CC=`xcrun -find -sdk iphoneos gcc`
    echo "----------------- Configuring for iPhone Simulator x86_64 --------------------"
    ./configure-iphone --prefix='' --with-ssl=${OPENSSL}
    echo "----------------- Making for iPhone Simulator  x86_64 ------------------------"
    make dep && make clean && make && make install

    export LIBDIR="${DESTDIR}/lib"
    export INCDIR="${DESTDIR}/include"

    export DESTDIR=${QLIQPROJECT_DIR}/shared/pjsip/pjsip-iphonesimulator

    # Merging Libraries using lipo
    for prefix in ${PJSIPLIBS}
    do
      echo "lipo -create ${prefix}"
      lipo -create ${LIBDIR}/${prefix}-i386-${TARGET}.a ${LIBDIR}/${prefix}-x86_64-${TARGET}.a -output ${DESTDIR}/lib/${prefix}-${TARGET2}.a
      echo "rm ${prefix}"
      rm ${LIBDIR}/${prefix}-i386-${TARGET}.a ${LIBDIR}/${prefix}-x86_64-${TARGET}.a
    done

    mkdir -p ${DESTDIR}/include
    echo "Copying include files to ${DESTDIR}/include"
    cp -R ${INCDIR} ${DESTDIR}

  fi
done

cd ${QLIQIPHONE_DIR}
