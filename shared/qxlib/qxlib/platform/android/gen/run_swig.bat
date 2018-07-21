SET OUTDIR=java

mkdir %OUTDIR%
c:\utils\swigwin-3.0.12\swig -c++ -java -package com.qliqsoft.qx.web -outdir %OUTDIR% -I..\..\..\.. ..\web.i

c:\Utils\portable_git\bin\sed -i 's/, false)/, true)/g' %OUTDIR%\qxwebJNI.java
pause