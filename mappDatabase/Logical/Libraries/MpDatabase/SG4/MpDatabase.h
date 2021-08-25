/* Automation Studio generated header file */
/* Do not edit ! */
/* MpDatabase 5.14.1 */

#ifndef _MPDATABASE_
#define _MPDATABASE_
#ifdef __cplusplus
extern "C" 
{
#endif
#ifndef _MpDatabase_VERSION
#define _MpDatabase_VERSION 5.14.1
#endif

#include <bur/plctypes.h>

#ifndef _BUR_PUBLIC
#define _BUR_PUBLIC
#endif
#ifdef _SG3
		#include "MpBase.h"
		#include "AsHttp.h"
#endif

#ifdef _SG4
		#include "MpBase.h"
		#include "AsHttp.h"
#endif

#ifdef _SGC
		#include "MpBase.h"
		#include "AsHttp.h"
#endif



/* Datatypes and datatypes of function blocks */
typedef enum MpDatabaseErrorEnum
{	mpDATABASE_NO_ERROR = 0,
	mpDATABASE_ERR_ACTIVATION = -1064239103,
	mpDATABASE_ERR_MPLINK_NULL = -1064239102,
	mpDATABASE_ERR_MPLINK_INVALID = -1064239101,
	mpDATABASE_ERR_MPLINK_CHANGED = -1064239100,
	mpDATABASE_ERR_MPLINK_CORRUPT = -1064239099,
	mpDATABASE_ERR_MPLINK_IN_USE = -1064239098,
	mpDATABASE_ERR_CONFIG_INVALID = -1064239091,
	mpDATABASE_ERR_SQL_SERVER = -1064167424,
	mpDATABASE_ERR_HTTP_SERVER = -1064167423,
	mpDATABASE_ERR_INVALID_QUERY = -1064167422,
	mpDATABASE_ERR_DUPLICATE_QUERY = -1064167421,
	mpDATABASE_INF_NO_DATA = 1083316228,
	mpDATABASE_ERR_INVALID_DATATYPE = -1064167419,
	mpDATABASE_INF_WAIT_CORE_FB = 1083316230,
	mpDATABASE_WRN_QUERY_RESULT = -2137909241,
	mpDATABASE_ERR_QUERY_RESULT = -1064167416,
	mpDATABASE_ERR_INVALID_USER = -1064167415
} MpDatabaseErrorEnum;

typedef struct MpDatabaseQueryRowsInfoType
{	unsigned long Total;
	unsigned long Read;
	unsigned long Remaining;
} MpDatabaseQueryRowsInfoType;

typedef struct MpDatabaseStatusIDType
{	enum MpDatabaseErrorEnum ID;
	MpComSeveritiesEnum Severity;
	unsigned short Code;
} MpDatabaseStatusIDType;

typedef struct MpDatabaseDiagType
{	struct MpDatabaseStatusIDType StatusID;
} MpDatabaseDiagType;

typedef struct MpDatabaseQueryInfoType
{	unsigned long ArraySize;
	struct MpDatabaseQueryRowsInfoType Rows;
	struct MpDatabaseDiagType Diag;
} MpDatabaseQueryInfoType;

typedef struct MpDatabaseCoreInfoType
{	struct MpDatabaseDiagType Diag;
} MpDatabaseCoreInfoType;

typedef struct MpDatabaseDateTimeType
{	plcdt DateTime;
	unsigned long Milliseconds;
} MpDatabaseDateTimeType;

typedef struct MpDatabaseCore
{
	/* VAR_INPUT (analog) */
	struct MpComIdentType* MpLink;
	/* VAR_OUTPUT (analog) */
	signed long StatusID;
	struct MpDatabaseCoreInfoType Info;
	/* VAR (analog) */
	struct MpComInternalDataType Internal;
	/* VAR_INPUT (digital) */
	plcbit Enable;
	plcbit ErrorReset;
	plcbit Connect;
	plcbit Disconnect;
	/* VAR_OUTPUT (digital) */
	plcbit Active;
	plcbit Error;
	plcbit CommandBusy;
	plcbit CommandDone;
	plcbit Connected;
} MpDatabaseCore_typ;

typedef struct MpDatabaseQuery
{
	/* VAR_INPUT (analog) */
	struct MpComIdentType* MpLink;
	plcstring (*Name);
	/* VAR_OUTPUT (analog) */
	signed long StatusID;
	struct MpDatabaseQueryInfoType Info;
	/* VAR (analog) */
	struct MpComInternalDataType Internal;
	/* VAR_INPUT (digital) */
	plcbit Enable;
	plcbit ErrorReset;
	plcbit Execute;
	plcbit Next;
	/* VAR_OUTPUT (digital) */
	plcbit Active;
	plcbit Error;
	plcbit CommandBusy;
	plcbit CommandDone;
} MpDatabaseQuery_typ;



/* Prototyping of functions and function blocks */
_BUR_PUBLIC void MpDatabaseCore(struct MpDatabaseCore* inst);
_BUR_PUBLIC void MpDatabaseQuery(struct MpDatabaseQuery* inst);


#ifdef __cplusplus
};
#endif
#endif /* _MPDATABASE_ */

