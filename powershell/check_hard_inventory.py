#!/usr/bin/python
# -*- coding: utf-8

#Возможно потребуется установить
#apt-get install python-mysqldb
#apt-get install python-dmidecode

import dmidecode
from pprint import pprint
import argparse
import socket
import platform


import MySQLdb
from datetime import date, datetime, timedelta
import string
import json


parser = argparse.ArgumentParser()
parser.add_argument('-H', '--hostname', dest='hostname',
                  help='Agent hostname', metavar='HOSTNAME')

args = parser.parse_args()

#print args.hostname

if args.hostname:
    agentName = args.hostname
else:
    agentName = socket.gethostname()


biosDict = {}
cpuDict = {}
systemDict = {}


# подключаемся к базе данных (не забываем указать кодировку, а то в базу запишутся иероглифы)
db = MySQLdb.connect(host="192.168.0.209", user="inventory_user", passwd="Z123456z", db="inventory", charset='utf8')
# формируем курсор, с помощью которого можно исполнять SQL-запросы
cursor = db.cursor()

# Шаблоны SQL запросов
sql_query_init = ("INSERT INTO tbComputerTarget "
               "(ComputerTargetId, Name, LastReportedInventoryTime) "
               "VALUES (%s, %s, %s)")

sql_query_del = "DELETE FROM tbComputerInventory WHERE (ComputerTargetId = %s AND ClassID = %s)"

sql_query = ("INSERT INTO tbComputerInventory "
               "(ComputerTargetId, ClassID, PropertyID, Value, InstanceId) "
               "VALUES (%s, %s, %s, %s, %s)")


############################################################################
#Заполняем таблицу tbComputerTarget
for v in dmidecode.system().values():
    if type(v) == dict and v['dmi_type'] == 1:
        systemDict["Manufacturer"] = str((v['data']['Manufacturer']))
        systemDict["Version"] = str((v['data']['Version']))
        systemDict["Product Name"] = str((v['data']['Product Name']))
        systemDict["Serial Number"] = str((v['data']['Serial Number']))
        systemDict["UUID"] = str((v['data']['UUID']))

computerUUID = systemDict["UUID"] + "-" + systemDict["Serial Number"]
reportDateTime = datetime.now().strftime('%Y-%m-%d %H:%M:%S')


sql_data = (computerUUID, agentName, reportDateTime)
cursor.execute(sql_query_init, sql_data)
db.commit()


###########################################################################
#tbComputerInventory

#ComputerSystem
sql_data = (computerUUID, 2)
cursor.execute(sql_query_del, sql_data)
db.commit()

sql_data = (computerUUID, 2, 86, systemDict["Manufacturer"], 1)
cursor.execute(sql_query, sql_data)
db.commit()
sql_data = (computerUUID, 2, 87, systemDict["Product Name"], 1)
cursor.execute(sql_query, sql_data)
db.commit()
sql_data = (computerUUID, 2, 85, socket.gethostname(), 1)
cursor.execute(sql_query, sql_data)
db.commit()


#BIOS
sql_data = (computerUUID, 1)
cursor.execute(sql_query_del, sql_data)
db.commit()

i = 1
for v in dmidecode.bios().values():
    if type(v) == dict and v['dmi_type'] == 0:
        biosDict["Vendor"] = str((v['data']['Vendor']))
        biosDict["Version"] = str((v['data']['Version']))
        biosDict["Release Date"] = str((v['data']['Release Date']))
        sql_data = (computerUUID, 1, 7, biosDict["Vendor"], i)
        cursor.execute(sql_query, sql_data)
        db.commit()
        sql_data = (computerUUID, 1, 6, biosDict["Version"], i)
        cursor.execute(sql_query, sql_data)
        db.commit()
        sql_data = (computerUUID, 1, 8, biosDict["Release Date"], i)
        cursor.execute(sql_query, sql_data)
        db.commit()
        biosName = 'BIOS Date: ' + biosDict["Release Date"] + ' Ver: ' + biosDict["Version"]
        sql_data = (computerUUID, 1, 5, biosName, i)
        cursor.execute(sql_query, sql_data)
        db.commit()
        i += 1


#Processor
sql_data = (computerUUID, 11)
cursor.execute(sql_query_del, sql_data)
db.commit()

i = 1
for v in dmidecode.processor().values():
    if type(v) == dict and v['dmi_type'] == 4:
        if str((v['data']['Family'])) != 'Unknown':
            cpuDict["Manufacturer"] = str((v['data']['Manufacturer']['Vendor']))
            cpuDict["Version"] = str((v['data']['Version']))
            cpuDict["Current Speed"] = str((v['data']['Current Speed']))
            sql_data = (computerUUID, 11, 4, cpuDict["Version"], i)
            cursor.execute(sql_query, sql_data)
            db.commit()
            sql_data = (computerUUID, 11, 3, cpuDict["Current Speed"], i)
            cursor.execute(sql_query, sql_data)
            db.commit()
            i += 1


#OperatingSystem
sql_data = (computerUUID, 8)
cursor.execute(sql_query_del, sql_data)
db.commit()

sql_data = (computerUUID, 8, 13, platform.platform(), 1)
cursor.execute(sql_query, sql_data)
db.commit()

osCaption = ' '.join(platform.dist()).strip().title()
sql_data = (computerUUID, 8, 15, osCaption, 1)
cursor.execute(sql_query, sql_data)
db.commit()

sql_data = (computerUUID, 8, 18, platform.release(), 1)
cursor.execute(sql_query, sql_data)
db.commit()

sql_data = (computerUUID, 8, 23, platform.version(), 1)
cursor.execute(sql_query, sql_data)
db.commit()

osArchitecture = platform.architecture()
sql_data = (computerUUID, 8, 117, osArchitecture[0], 1)
cursor.execute(sql_query, sql_data)
db.commit()



db.close()

print computerUUID
#print fqdn
print reportDateTime













'''
   Type   Information
       ----------------------------------------
          0   BIOS
          1   System
          2   Base Board
          3   Chassis
          4   Processor
          5   Memory Controller
          6   Memory Module
          7   Cache
          8   Port Connector
          9   System Slots
         10   On Board Devices
         11   OEM Strings
         12   System Configuration Options
         13   BIOS Language
         14   Group Associations
         15   System Event Log
         16   Physical Memory Array
         17   Memory Device
         18   32-bit Memory Error
         19   Memory Array Mapped Address
         20   Memory Device Mapped Address
         21   Built-in Pointing Device
         22   Portable Battery
         23   System Reset
         24   Hardware Security
         25   System Power Controls
         26   Voltage Probe
         27   Cooling Device
         28   Temperature Probe
         29   Electrical Current Probe
         30   Out-of-band Remote Access
         31   Boot Integrity Services
         32   System Boot
         33   64-bit Memory Error
         34   Management Device
         35   Management Device Component
         36   Management Device Threshold Data
         37   Memory Channel
         38   IPMI Device
         39   Power Supply


       Keyword     Types
       ------------------------------
       bios        0, 13
       system      1, 12, 15, 23, 32
       baseboard   2, 10
       chassis     3
       processor   4
       memory      5, 6, 16, 17
       cache       7
       connector   8
       slot        9
'''
