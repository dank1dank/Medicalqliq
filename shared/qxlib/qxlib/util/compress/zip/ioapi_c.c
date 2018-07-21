#include <stdio.h>
#include "zlib.h"
#include "ioapi.h"

static voidpf ZCALLBACK fopen_file_func (voidpf opaque, const char* filename, int mode)
{
    FILE* file = NULL;
    const char* mode_fopen = NULL;
    if ((mode & ZLIB_FILEFUNC_MODE_READWRITEFILTER)==ZLIB_FILEFUNC_MODE_READ)
    mode_fopen = "rb";
    else
    if (mode & ZLIB_FILEFUNC_MODE_EXISTING)
    mode_fopen = "r+b";
    else
    if (mode & ZLIB_FILEFUNC_MODE_CREATE)
    mode_fopen = "wb";

    if ((filename!=NULL) && (mode_fopen != NULL))
    file = fopen(filename, mode_fopen);
    return file;
}

static uLong ZCALLBACK fread_file_func (voidpf opaque, voidpf stream, void* buf, uLong size)
{
    uLong ret;
    ret = (uLong)fread(buf, 1, (size_t)size, (FILE *)stream);
    return ret;
}

static uLong ZCALLBACK fwrite_file_func (voidpf opaque, voidpf stream, const void* buf, uLong size)
{
    uLong ret;
    ret = (uLong)fwrite(buf, 1, (size_t)size, (FILE *)stream);
    return ret;
}

static long ZCALLBACK ftell_file_func (voidpf opaque, voidpf stream)
{
    long ret;
    ret = ftell((FILE *)stream);
    return ret;
}

static long ZCALLBACK fseek_file_func (voidpf  opaque, voidpf stream, uLong offset, int origin)
{
    int fseek_origin=0;
    long ret;
    switch (origin)
    {
    case ZLIB_FILEFUNC_SEEK_CUR :
    fseek_origin = SEEK_CUR;
    break;
    case ZLIB_FILEFUNC_SEEK_END :
    fseek_origin = SEEK_END;
    break;
    case ZLIB_FILEFUNC_SEEK_SET :
    fseek_origin = SEEK_SET;
    break;
    default: return -1;
    }
    ret = 0;
    if (fseek((FILE *)stream, offset, fseek_origin) != 0)
    ret = -1;
    return ret;
}

static int ZCALLBACK fclose_file_func (voidpf opaque, voidpf stream)
{
    int ret;
    ret = fclose((FILE *)stream);
    return ret;
}

static int ZCALLBACK ferror_file_func (voidpf opaque, voidpf stream)
{
    int ret;
    ret = ferror((FILE *)stream);
    return ret;
}

void fill_fopen_filefunc (zlib_filefunc_def* pzlib_filefunc_def)
{
    pzlib_filefunc_def->zopen_file = fopen_file_func;
    pzlib_filefunc_def->zread_file = fread_file_func;
    pzlib_filefunc_def->zwrite_file = fwrite_file_func;
    pzlib_filefunc_def->ztell_file = ftell_file_func;
    pzlib_filefunc_def->zseek_file = fseek_file_func;
    pzlib_filefunc_def->zclose_file = fclose_file_func;
    pzlib_filefunc_def->zerror_file = ferror_file_func;
    pzlib_filefunc_def->opaque = NULL;
}
