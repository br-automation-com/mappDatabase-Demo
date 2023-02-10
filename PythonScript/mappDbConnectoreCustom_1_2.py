#!/usr/bin/env python
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
from operator import truediv
from pickle import TRUE
import ssl
import datetime
import urllib.parse
import socketserver
import collections
import decimal
import re
import sys

__version__ = "5.12.0"
	
# ----------------------------------------------------------------------------------------------------------------------
# Define field types
FieldType_BIT = 16
FieldType_VAR_STRING = 253
FieldType_DATE = 10
FieldType_TIME = 11
FieldType_DATETIME = 12
FieldType_TINY = 1
FieldType_FLOAT = 4
FieldType_NEWDECIMAL = 246
FieldType_DOUBLE = 5
FieldType_SHORT = 2
FieldType_LONGLONG = 8

# ----------------------------------------------------------------------------------------------------------------------
# Dictionary for translating odbc datatype to MpDatabase approved types (currenly based on MySql type table)
pyodbc_mysql_datatype_map = {
	bool: (FieldType_BIT),
	str: (FieldType_VAR_STRING),
	datetime.date: (FieldType_DATE),
	datetime.time: (FieldType_TIME),
	datetime.datetime: (FieldType_DATETIME),
	int: (FieldType_TINY),
	float: (FieldType_FLOAT),
	str: (FieldType_VAR_STRING),
	decimal.Decimal: (FieldType_NEWDECIMAL)
}

mysql_info_map = {
	FieldType_BIT: 'BIT',
	FieldType_FLOAT: 'FLOAT',
	FieldType_DOUBLE: 'DOUBLE',
	FieldType_SHORT: 'SHORT',
	FieldType_TINY: 'TINY',
	FieldType_LONGLONG: 'LONGLONG',
	FieldType_DATE: 'DATE',
	FieldType_TIME: 'TIME',
	FieldType_DATETIME: 'DATETIME',
	FieldType_NEWDECIMAL: 'FLOAT',
	FieldType_VAR_STRING: 'VAR_STRING'
}

psycopg2_mysql_datatype_map = {
	16: (FieldType_BIT),#bool
	700: (FieldType_FLOAT),#float
	701: (FieldType_DOUBLE),#double precision
	21: (FieldType_SHORT),#smallint
	23: (FieldType_TINY),#integer
	20: (FieldType_LONGLONG),#bigint
	1043: (FieldType_VAR_STRING),#character varying
	25: (FieldType_VAR_STRING),#unicode
	1082: (FieldType_DATE),#date
	1083: (FieldType_TIME),#timewithouttimezone
	1114: (FieldType_DATETIME),#timestampwithouttimezone
	1700: (FieldType_FLOAT),#numeric
	1042: (FieldType_VAR_STRING)#character
}

disconnect = False

# ----------------------------------------------------------------------------------------------------------------------
# MSSQL Float storage size is specification: https://docs.microsoft.com/en-us/sql/t-sql/data-types/float-and-real-transact-sql?view=sql-server-2017
def specifyFloat(internalSize):
	if 1<=internalSize<=24:
		return FieldType_FLOAT
	else:
		return FieldType_DOUBLE

def specifyLongLong(internalSize):
	if internalSize < 19:
		return FieldType_TINY
	else:
		return FieldType_LONGLONG
		
# ----------------------------------------------------------------------------------------------------------------------
def makeJsonResponse(status, message, response):
	data = {}
	data['status'] = status
	data['message'] = message
	data['response'] = response
	return json.dumps(data, default=myconverter)

# ----------------------------------------------------------------------------------------------------------------------
def debug_log(text):
	if len(args.l) > 0:
		try:
			with open(args.l, 'w+') as f:
				f = open(args.l, 'w+')
				f.write(makeJsonResponse(0, "",text))
		except:
			print('Can not log to file "{0}"'.format(args.l))

# ----------------------------------------------------------------------------------------------------------------------
def debug_print(error, msg):
	print("Exception: code %s, message %s" % (str(error),msg))

# ----------------------------------------------------------------------------------------------------------------------
def sqlToJson(column_names, dataIn, colTypes):
	types = []
	for desc in colTypes:
		# SQL type is Micorosft SQL
		if(args.sqlType == 'mssql'):
			coltype = pyodbc_mysql_datatype_map[desc[1]]
			if coltype == FieldType_FLOAT:
				coltype = specifyFloat(desc[3])
			if coltype == FieldType_TINY:
				coltype = specifyLongLong(desc[3])
		# SQL type is Postgres
		elif(args.sqlType == 'postgres'):
			coltype = psycopg2_mysql_datatype_map[desc[1]]
		else:
			coltype = desc[1]
	
		# add column type
		types.append(mysql_info_map[coltype])

	# Fill response with data
	data = []
	for row in dataIn:
		i = 0
		dataRow = collections.OrderedDict()
		for field in row:
			# Trim string values
			if(isinstance(field, str)):
				dataRow[column_names[i]] = field.strip()
			else:
				dataRow[column_names[i]] = field
			i = i + 1
		data.append(dataRow)
	response = {}
	response['data'] = data
	response['columns'] = column_names
	response['types'] = types
	return response

# ----------------------------------------------------------------------------------------------------------------------
def makeDateTime(o, onlyTime = False):
	value = {}
	try:
		value['year'] = o.year
	except:
		value['year'] = 0
	try:
		value['month'] = o.month
	except:
		value['month'] = 0
	try:
		value['day'] = o.day
	except:
		value['day'] = 0
	try:
		value['wday'] = o.weekday()
	except:
		value['wday'] = 0
	try:
		value['hour'] = o.hour
	except:
		value['hour'] = 0
	try:
		value['minute'] = o.minute
	except:
		value['minute'] = 0
	try:
		value['second'] = o.second
	except:
		value['second'] = 0
	try:
		value['millisecond'] = o.microsecond / 1000
	except:
		value['millisecond'] = 0
	try:
		value['microsecond'] = o.microsecond - value['millisecond']*1000
	except:
		value['microsecond'] = 0
	if onlyTime:
		value['year'] = 0
		value['month'] = 0
		value['wday'] = 0
	return value
	
# ----------------------------------------------------------------------------------------------------------------------
def makeTime(o):
	SECONDS_PER_DAY = 86400
	SECONDS_PER_HOUR = 3600
	SECONDS_PER_MINUTE = 60

	value = {}
	totalMicroSecs = (o.days * SECONDS_PER_DAY + o.seconds) * 1000000 + o.microseconds
	totalSeconds = int(totalMicroSecs / 1000000.0)
	totalMicroSecs -= totalSeconds * 1000000
	totalSeconds *= -1
	totalMicroSecs *= -1

	try:
		value['day'] = int( totalSeconds / (SECONDS_PER_DAY * 1.0)) * -1
	except:
		value['day'] = 0	
	totalSeconds += value['day'] * SECONDS_PER_DAY  	
	try:
		value['hour'] = int(totalSeconds / (SECONDS_PER_HOUR * 1.0))
	except:
		value['hour'] = 0		
	totalSeconds -= value['hour'] * SECONDS_PER_HOUR  
	try:
		value['minute'] = int((totalSeconds) / (SECONDS_PER_MINUTE * 1.0))
	except:
		value['minute'] = 0
	totalSeconds -= value['minute'] * SECONDS_PER_MINUTE
	try:
		value['second'] = totalSeconds
	except:
		value['second'] = 0
	try:
		value['millisecond'] = totalMicroSecs / 1000
	except:
		value['millisecond'] = 0

	value['microsecond'] = 0
	return value

# ----------------------------------------------------------------------------------------------------------------------
def myconverter(o):
	if isinstance(o, datetime.datetime) or isinstance(o, datetime.date) or isinstance(o, datetime.timedelta) or isinstance(o, datetime.time):
		if isinstance(o, datetime.timedelta):
			if o.days > 0:
				# pass as datetime object, because we have to represent days
				return makeDateTime((datetime.datetime.min + o) - datetime.timedelta(days=1),True)
			elif o.days == 0:
				return makeDateTime((datetime.datetime.min + o).time())
			else:
				return makeTime(o)
		else:
			return makeDateTime(o)
	elif isinstance(o, decimal.Decimal):
		return float(o) # python's float has double precision
		
# ----------------------------------------------------------------------------------------------------------------------
class DB:

	_user = None
	_password = None
	_host = None
	_database = None
	_cnx = None
	_jsonResponse = None

	# ----------------------------------------------------------------------------------------------------------------------
	# Connect to database
	def connect(self, user, password, host, port, database):
		self._user = user
		self._password = password
		self._host = host
		self._database = database
		self._port = port

		try:
			# Database type is Microsoft SQL
			if(args.sqlType == 'mssql'):
				print('Using Microsoft ODBC driver.')
				import pyodbc
				server = str(self._host) + ',' + str(self._port)
				self._cnx = pyodbc.connect(driver='{ODBC Driver 17 for SQL Server}',
										server=server,
										database=self._database,
										uid=self._user, pwd=self._password,
										autocommit=True)
			# Database type is Postgres
			elif(args.sqlType == 'postgres'):
				print('Using postgres driver.')
				import psycopg2
				self._cnx = psycopg2.connect(user=self._user, password=self._password,
											host=self._host,
											database=self._database,
											port=self._port)
				self._cnx.autocommit = True
			# Default database type is MySQL
			else:
				print('Using generic MySql driver.')
				import mysql.connector
				self._cnx = mysql.connector.connect(user=self._user, password=self._password,
													host=self._host,
													database=self._database,
													port=self._port)

		except Exception as ex:
			if("No module named 'mysql'" in str(ex)):
				print('MySql driver is not installed. Press -enter- to exit script.')
			elif("No module named 'pyodbc'" in str(ex)):
				print('PyODBC driver is not installed. Press -enter- to exit script.')
			else:
				print(ex)

			input()
			quit()

	# ----------------------------------------------------------------------------------------------------------------------
	def disconnect(self):
		try:
			self._cnx.close()
			print('------------------------------------------------------------------------------')
			print('PLC disconnected')
			return makeJsonResponse(0, "disconnected", "")
		except Exception as ex:
			print("Not connected to sql server")
			return makeJsonResponse(1, "not connected to sql server", "")

	# ----------------------------------------------------------------------------------------------------------------------
	def getData(self):
		return self._jsonResponse

	# ----------------------------------------------------------------------------------------------------------------------
	def query(self, sql):
		try:
			if (args.sqlType == 'mssql') or (args.sqlType == 'postgres'):
				cursor = self._cnx.cursor()
			else:
				cursor = self._cnx.cursor(buffered=True)
		except Exception as ex:
			debug_print(1, str(ex))
			return makeJsonResponse(1, "not connected to sql server", "")

		try:
			print('Query request: ' + sql)
		except Exception as ex:
			print('Query will be executed: error printing the query. Check special characters and encoding.')
		print('------------------------------------------------------------------------------')

		# split multistatement queries, but ignore semicolon within queries
		for statement in re.sub(r'(\)\s*);', r'\1%;%', sql).split('%;%'):
			cursor.execute(statement)

		data = []
		response = {}
		# Always try to fetch data independent of insert / select
		try:
			data = cursor.fetchall()
		except Exception as ex:
			pass

		# ----------------------------------------------------------------------------------------------------------------------
		# Cursor description is available if there was a response. Hence we create the json response that can later be forwared
		if(cursor.description):
			if(args.sqlType == 'mssql') or (args.sqlType == 'postgres'):
				column_names = [column[0] for column in cursor.description]
			else:
				column_names = cursor.column_names

			if(len(column_names) == 1) and (column_names[0] == ''):
				print('Warning: No column names found')
				print('------------------------------------------------------------------------------')
				print('Query response: ' + str(data))
			else:
				print('Query response with ' + str(len(data)) + ' total rows')

				for row in data:
					i = 0
					for field in row:
						print(str(column_names[i]) + ': ' + str(field).strip())
						i = i + 1
					print('------------------------------------------------------------------------------')

			response = sqlToJson(column_names, data, cursor.description)

		self._cnx.commit()
		cursor.close()
		debug_log(response)
		self._jsonResponse = makeJsonResponse(0, "", response)
		return json.dumps({"responseSize":len(self._jsonResponse)})
		
# ----------------------------------------------------------------------------------------------------------------------
class S(BaseHTTPRequestHandler):

	__sqlDb = DB()
	
	# ----------------------------------------------------------------------------------------------------------------------
	# Override method to modify the message show in the console due to timeout
	def handle_one_request(self):
		try:
			self.raw_requestline = self.rfile.readline(65537)
			if len(self.raw_requestline) > 65536:
				self.requestline = ''
				self.request_version = ''
				self.command = ''
				self.send_error(414)
				return
			if not self.raw_requestline:
				self.close_connection = 1
				return
			if not self.parse_request():
				# An error code has been sent, just exit
				return
			mname = 'do_' + self.command
			if not hasattr(self, mname):
				self.send_error(501, "Unsupported method (%r)" % self.command)
				return
			method = getattr(self, mname)
			method()
			self.wfile.flush() #actually send the response if not already done.
		except socketserver.socket.timeout as e:
			global disconnect
			disconnect = True
			self.do_POST()
			self.close_connection = 1
			return
	
	# ----------------------------------------------------------------------------------------------------------------------
	# Override method to set a timeout
	def setup(self):
		BaseHTTPRequestHandler.setup(self)
		self.request.settimeout(args.httpTimeout)
		
	# ----------------------------------------------------------------------------------------------------------------------
	def _set_headers(self, contentLength):
		self.send_response(200)
		self.send_header('Content-type', 'text/html')
		self.send_header("Content-Length", contentLength)
		self.send_header("Connection", "Keep-Alive")
		self.end_headers()

	# ----------------------------------------------------------------------------------------------------------------------
	def _respond(self, jsonResponse):
		self._set_headers(len(jsonResponse))
		self.wfile.write(bytes(jsonResponse, "utf-8"))

	# ----------------------------------------------------------------------------------------------------------------------
	def do_GET(self):
		self._set_headers(len("server up.."))
		self.wfile.write("server up..")
		
	# ----------------------------------------------------------------------------------------------------------------------
	def do_POST(self):
		global disconnect
		if disconnect:
			self._respond(self.__sqlDb.disconnect())
			disconnect = False
		else:
			# FIXME: handle invalid request
			length = int(self.headers.get('content-length'))
			data = urllib.parse.parse_qs(self.rfile.read(length).decode('utf-8'), keep_blank_values=1, encoding='utf-8')
			print('------------------------------------------------------------------------------')
			try:
				print('PLC data: ' + str(data))
			except Exception as ex:
				print('Query will be executed: error printing the query. Check special characters and encoding.')

			jsonRequest = list(data.items())[0][0]

			try:
				serialized = json.loads(jsonRequest)
			except Exception as ex:
				print('failed parsing {0}'.format(jsonRequest))
				self._respond(makeJsonResponse(2, "", {}))
				return

			try:
				if "getData" in serialized:
					# get actual data
					self._respond(self.__sqlDb.getData())
				else:
					# Execute query to get response size
					execQuery = serialized['query']

					if(args.sqlType == 'mssql') or (args.sqlType == 'postgres'):
						execQuery = execQuery.translate({ord(c): None for c in '`'})
					else:
						execQuery = execQuery
					self._respond(self.__sqlDb.query(execQuery))
			except KeyError:
				try:
					# try to connect and do test query
					connection = serialized['connection'][0]
					if 'libraryVersion' in connection:
						print('------------------------------------------------------------------------------')
						print('PLC connected')
						#import pdb; pdb.set_trace()
						from pkg_resources  import parse_version
						minVersion = parse_version(connection['minScriptVersion'])
						maxVersion = parse_version(connection['maxScriptVersion'])
						scriptVersion = parse_version(__version__)
						#import pdb; pdb.set_trace()
						if ((minVersion <= scriptVersion) and  (scriptVersion <= maxVersion)):
							self.__sqlDb.connect(connection['user'], connection['password'], args.sqlHost, args.sqlPort, connection['database'])
							self._respond(makeJsonResponse(0, "",{'timeout': args.httpTimeout, 'dbms': args.sqlType, 'VO': 'active'}))
						else:
							self._respond(makeJsonResponse(3, __version__,""))
							print("Version mismatch: MpDatabase " + connection['libraryVersion'] + " is not compatible with mappDatabaseConnector " + __version__ + " (compatible Versions: " + connection['minScriptVersion'] + " - " + connection['maxScriptVersion'] + ")")
					else:
						print("Version mismatch. It is not allowed to use a mappDatabaseConnector with higher version than MpDatabase.")						
						self._respond(makeJsonResponse("Version mismatch", "It is not allowed to use a mappDatabaseConnector with higher version than MpDatabase.",""))
				except KeyError:
					# try to disconnect
					self._respond(self.__sqlDb.disconnect())
				except Exception as ex:
					if (args.sqlType == 'postgres'):
						debug_print("PostgreSQL error:",str(ex))
						self._respond(makeJsonResponse(ex.args[0], "", ""))
					else:
						debug_print(ex.args[0],ex.args[1])
						self._respond(makeJsonResponse(ex.args[0], ex.args[1], ""))

			except Exception as ex:
				if (args.sqlType == 'postgres'):
					debug_print("PostgreSQL error:",str(ex))
					self._respond(makeJsonResponse(ex.args[0], "", ""))
				else:
					debug_print(ex.args[0],ex.args[1])
					self._respond(makeJsonResponse(ex.args[0], ex.args[1], ""))
					self._respond(self.__sqlDb.disconnect())
		
# ----------------------------------------------------------------------------------------------------------------------
def run(server_class=HTTPServer, handler_class=S, webServerPort=85):
	if (args.httpTimeout < 10):
		sys.exit("Timeout not valid. Please introduce a timeout higher than 10 seconds")
	elif (args.httpTimeout >= 600):
		print("Warning: In case the PLC got restarted while a connection between mapp Database and the script was active a timeout of {} seconds will pass before connection is established again.".format(args.httpTimeout))

	handler_class.protocol_version = 'HTTP/1.1'
	httpd = socketserver.TCPServer(("",webServerPort),handler_class)
	print('------------------------------------------------------------------------------')
	print('Starting Python script on port ' + str(webServerPort))
	print('SQL server host ' + args.sqlHost + ':' + str(args.sqlPort))

	# FIXME: line below sets up HTTPS server, but it is args.sqlType yet supported from a client side
	# httpd.socket = ssl.wrap_socket (httpd.socket, certfile='./server.pem', server_side=True)
	while True:
		httpd.handle_request()
	
# ----------------------------------------------------------------------------------------------------------------------
if __name__ == "__main__":
	import argparse
	parser = argparse.ArgumentParser(
		description='This script works as a bridge between MpDatabase and defined SQL server',
		epilog='EXAMPLES:\n\n# start the script with default parameters (85, 127.0.0.1, 3306, mysql, 60)\n$ python mappDatabaseConnector.py\n\n# start the script with defined parameters (e.g. 86, 192.168.1.15, 58964, mssql, 30)\n$ python mappDatabaseConnector.py 86 \'192.168.1.15\' 58964 \'mssql\' 30\n\n# start the script with defined parameters (e.g. 86, 127.0.0.1, 5432, postgres, 60)\n$ python mappDatabaseConnector.py 86 \'127.0.0.1\' 5432 \'postgres\' 60 ',
		formatter_class=argparse.RawDescriptionHelpFormatter)
	parser.add_argument('httpPort', type=str,
					default='85', const=1, nargs='?',
					help='http server port (default: 85)')
	parser.add_argument('sqlHost', type=str,
					default='127.0.0.1', const=1, nargs='?',
					help='sql server host (default: 127.0.0.1)')
	parser.add_argument('sqlPort', type=int,
					default=3306, const=1, nargs='?',
					help='sql server port (default: 3306)')
	parser.add_argument('sqlType', type=str,
					default='mysql', const=1, nargs='?',
					help='sql server type: mysql, mssql, postgres (default: mysql)')
	parser.add_argument('httpTimeout', type=int,
					default=60, const=1, nargs='?',
					help='Timeout in seconds without incoming http requests (default: 60)')
	parser.add_argument('--version', action='version',
					version='%(prog)s {version}'.format(version=__version__))
	parser.add_argument('-l', type=str,
					const=1, nargs='?', default='',
					help='File name (full path) to log SQL response. File must be writable, data is overwritten')
	args = parser.parse_args()

	run(webServerPort=int(args.httpPort))