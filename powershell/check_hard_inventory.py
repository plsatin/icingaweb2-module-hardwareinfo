#!/usr/bin/python
# -*- coding: utf-8

#Возможно потребуется установить
#apt-get install python-mysqldb


import MySQLdb
from datetime import date, datetime, timedelta
import string
import json
import subprocess



subprocess.call('lshw -json > /tmp/hw.info.json', shell=True)
#Загружаем файл в формате json сформированный утилитой lshw
data = json.load(open('/tmp/hw.info.json'))

computerUUID = data["configuration"]["uuid"] + "-" + data["serial"]
fqdn = "icinga" #data["id"]
reportDateTime = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

# подключаемся к базе данных (не забываем указать кодировку, а то в базу запишутся иероглифы)
db = MySQLdb.connect(host="192.168.0.209", user="inventory_user", passwd="Z123456z", db="inventory", charset='utf8')
# формируем курсор, с помощью которого можно исполнять SQL-запросы
cursor = db.cursor()

############################################################################
#Заполняем таблицу tbComputerTarget

sql_query = ("INSERT INTO tbComputerTarget "
               "(ComputerTargetId, Name, LastReportedInventoryTime) "
               "VALUES (%s, %s, %s)")
sql_data = (computerUUID, fqdn, reportDateTime)
cursor.execute(sql_query, sql_data)
db.commit()

###################################
#Отправляем сведения о железе


cpu_product = data["children"][0]["children"][1]["product"]
cpu_size = data["children"][0]["children"][1]["size"] / 1000000
cpu_id = data["children"][0]["children"][1]["id"]


sql_query = ("INSERT INTO tbComputerInventory "
               "(ComputerTargetId, ClassID, PropertyID, Value, InstanceId) "
               "VALUES (%s, %s, %s, %s, %s)")
sql_data = (computerUUID, 11, 4, cpu_product, 1)
cursor.execute(sql_query, sql_data)
db.commit()

sql_query = ("INSERT INTO tbComputerInventory "
               "(ComputerTargetId, ClassID, PropertyID, Value, InstanceId) "
               "VALUES (%s, %s, %s, %s, %s)")
sql_data = (computerUUID, 11, 1, cpu_id, 1)
cursor.execute(sql_query, sql_data)
db.commit()


sql_query = ("INSERT INTO tbComputerInventory "
               "(ComputerTargetId, ClassID, PropertyID, Value, InstanceId) "
               "VALUES (%s, %s, %s, %s, %s)")
sql_data = (computerUUID, 11, 3, cpu_size, 1)
cursor.execute(sql_query, sql_data)
db.commit()






db.close()

print computerUUID
#print fqdn
print reportDateTime
