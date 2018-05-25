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
ramADict = {}
ramDict = {}


# подключаемся к базе данных (не забываем указать кодировку, а то в базу запишутся иероглифы)
db = MySQLdb.connect(host="192.168.0.209", user="user", passwd="password", db="inventory", charset='utf8')
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
            cpuDict["Family"] = str((v['data']['Family']))
            cpuDict["DeviceID"] = str((v['data']['Manufacturer']['ID']))
            cpuDict["Description"] = str((v['data']['Manufacturer']['Signature']))
            sql_data = (computerUUID, 11, 206, cpuDict["Manufacturer"], i)
            cursor.execute(sql_query, sql_data)
            db.commit()
            sql_data = (computerUUID, 11, 207, cpuDict["Description"], i)
            cursor.execute(sql_query, sql_data)
            db.commit()
            sql_data = (computerUUID, 11, 1, cpuDict["DeviceID"], i)
            cursor.execute(sql_query, sql_data)
            db.commit()
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


#Memory array
sql_data = (computerUUID, 28)
cursor.execute(sql_query_del, sql_data)
db.commit()

i = 1
for v in dmidecode.memory().values():
    if type(v) == dict and v['dmi_type'] == 16:
        ramADict["MaxCapacity"] = str((v['data']['Maximum Capacity']))
        ramADict["MemoryDevices"] = str((v['data']['Number Of Devices']))
        ramADict["Name"] = str((v['data']['Use']))
        sql_data = (computerUUID, 28, 204, ramADict["MemoryDevices"], i)
        cursor.execute(sql_query, sql_data)
        db.commit()
        sql_data = (computerUUID, 28, 203, ramADict["MaxCapacity"], i)
        cursor.execute(sql_query, sql_data)
        db.commit()
        sql_data = (computerUUID, 28, 202, ramADict["Name"], i)
        cursor.execute(sql_query, sql_data)
        db.commit()
        i += 1

#Memory
sql_data = (computerUUID, 15)
cursor.execute(sql_query_del, sql_data)
db.commit()

i = 1
for v in dmidecode.memory().values():
    if type(v) == dict and v['dmi_type'] == 17:
        ramDict["DeviceLocator"] = str((v['data']['Locator']))
        ramDict["Speed"] = str((v['data']['Speed']))
        ramDict["Name"] = 'Physical memory'
        ramDict["MemoryType"] = str((v['data']['Type']))
        ramDict["Manufacturer"] = str((v['data']['Manufacturer']))
        ramDict["Capacity"] = str((v['data']['Size']))
        sql_data = (computerUUID, 15, 104, ramDict["Name"], i)
        cursor.execute(sql_query, sql_data)
        db.commit()
        sql_data = (computerUUID, 15, 103, ramDict["Name"], i)
        cursor.execute(sql_query, sql_data)
        db.commit()
        sql_data = (computerUUID, 15, 105, ramDict["DeviceLocator"], i)
        cursor.execute(sql_query, sql_data)
        db.commit()
        sql_data = (computerUUID, 15, 106, ramDict["Capacity"], i)
        cursor.execute(sql_query, sql_data)
        db.commit()
        sql_data = (computerUUID, 15, 107, ramDict["Speed"], i)
        cursor.execute(sql_query, sql_data)
        db.commit()
        sql_data = (computerUUID, 15, 109, ramDict["Manufacturer"], i)
        cursor.execute(sql_query, sql_data)
        db.commit()
        i += 1











db.close()

print computerUUID
#print fqdn
print reportDateTime



