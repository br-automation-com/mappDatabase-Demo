## Table of Contents
* [Introduction](#Introduction)
* [Python script changes](#Script)
* [Requirements](#Requirements)
* [Revision History](#Revision-History)

<a name="Introduction"></a>
## Introduction
This is a demo application for a simple recipe managment with mappDatabase. It is not and official B&R product. See the [WIKI](https://github.com/br-automation-com/mappDatabase-Demo/wiki) for a detailed guide how to setup different SQL servers. 

![](https://github.com/br-automation-com/mappDatabase-Demo/blob/main/Wiki/screenshot.png)

<a name="Script"></a>
## Python script changes
This sample also includes a customized version of the Python script used to connect to the database server. The script is fully compatible with the B&R script. See Automation Studio help (e046127f-e239-4f17-bd17-3ae889dac782) and the [WIKI](https://github.com/br-automation-com/mappDatabase-Demo/wiki) for more details how to use the script.

#### The script changes include:
- Added more and detailed error messages
- Print all SQL queries and server response details
- Trim data type string when reading from database
- Change MsSQL database provider to 'ODBC Driver 17 for SQL Server' to support Linux systems
- Removed dependency from MySql driver for data conversion. It is no longer required to install MySQL driver when using MsSQL.

<a name="Requirements"></a>
## Requirements (current used versions)
* Automation Studio 4.9
* mapp 5.14
* Automation Runtime B4.83

Recommended task class is #8 with a 10ms cycle time. For the nettime and axis tasks use #1

<a name="Revision-History"></a>
## Revision History
You can find details in the project in "revision.txt"

#### Version 1.1 (05.01.2022)
- Added script server ping
- PLC: Update to runtime E4.90 and mapp 5.16
- PythonScript: Added PLC raw data to debug output

#### Version 1.0
- First public release

