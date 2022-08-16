# Webhook receiver for getting data from ATV devices
# replacement for ATVdetails
#
__author__ = "GhostTalker"
__copyright__ = "Copyright 2022, The GhostTalker project"
__version__ = "0.2.2"
__status__ = "DEV"

import os
import sys
import time
import datetime
import json
import requests
import configparser
import pymysql
from mysql.connector import Error
from mysql.connector import pooling
from flask import Flask, request

## read config
_config = configparser.ConfigParser()
_rootdir = os.path.dirname(os.path.abspath('config.ini'))
_config.read(_rootdir + "/config.ini")
_host = _config.get("socketserver", "host", fallback='0.0.0.0')
_port = _config.get("socketserver", "port", fallback='5050')
_mysqlhost = _config.get("mysql", "mysqlhost", fallback='127.0.0.1')
_mysqlport = _config.get("mysql", "mysqlport", fallback='3306')
_mysqldb = _config.get("mysql", "mysqldb")
_mysqluser = _config.get("mysql", "mysqluser")
_mysqlpass = _config.get("mysql", "mysqlpass")

## do validation and checks before insert
def validate_string(val):
   if val != None:
        if type(val) is int:
            #for x in val:
            #   print(x)
            return str(val).encode('utf-8')
        else:
            return val

## create connection pool and connect to MySQL
try:
    connection_pool = pooling.MySQLConnectionPool(pool_name="mysql_connection_pool",
                                                  pool_size=5,
                                                  pool_reset_session=True,
                                                  host=_mysqlhost,
                                                  port=_mysqlport,
                                                  database=_mysqldb,
                                                  user=_mysqluser,
                                                  password=_mysqlpass)

    print("Create connection pool: ")
    print("Connection Pool Name - ", connection_pool.pool_name)
    print("Connection Pool Size - ", connection_pool.pool_size)

    # Get connection object from a pool
    connection_object = connection_pool.get_connection()

    if connection_object.is_connected():
        db_Info = connection_object.get_server_info()
        print("Connected to MySQL database using connection pool ... MySQL Server version on ", db_Info)

        cursor = connection_object.cursor()
        cursor.execute("select database();")
        record = cursor.fetchone()
        print("You're connected to - ", record)

except Error as e:
    print("Error while connecting to MySQL using Connection pool ", e)

finally:
    # closing database connection.
    if connection_object.is_connected():
        cursor.close()
        connection_object.close()
        print("MySQL connection is closed")

## webhook receiver
app = Flask(__name__)

@app.route('/webhook', methods=['POST'])
def webhook():
    if request.method == 'POST':
        print("Data received from Webhook is: ", request.json)

        # parse json data to SQL insert
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        origin = validate_string(request.json["origin"])
        arch = validate_string(request.json["arch"])
        productmodel = validate_string(request.json["productmodel"])
        vm_script = validate_string(request.json["vm_script"])
        vmapper55 = validate_string(request.json["vmapper55"])
        vmapper42 = validate_string(request.json["vmapper42"])
        pogo = validate_string(request.json["pogo"])
        vmapper = validate_string(request.json["vmapper"])
        pogo_update = validate_string(request.json["pogo_update"])
        vm_update = validate_string(request.json["vm_update"])
        temperature = validate_string(request.json["temperature"])
        magisk = validate_string(request.json["magisk"])
        magisk_modules = validate_string(request.json["magisk_modules"])
        macw = validate_string(request.json["macw"])
        mace = validate_string(request.json["mace"])
        ip = validate_string(request.json["ip"])
        ext_ip = validate_string(request.json["ext_ip"])
        diskSysPct = validate_string(request.json["diskSysPct"])
        diskDataPct = validate_string(request.json["diskDataPct"])
        bootdelay = validate_string(request.json["bootdelay"])
        gzip = validate_string(request.json["gzip"])
        betamode = validate_string(request.json["betamode"])
        selinux = validate_string(request.json["selinux"])
        daemon = validate_string(request.json["daemon"])
        authpassword = validate_string(request.json["authpassword"])
        authuser = validate_string(request.json["authuser"])
        authid = validate_string(request.json["authid"])
        postdest = validate_string(request.json["postdest"])
        fridastarted = validate_string(request.json["fridastarted"])
        patchedpid = validate_string(request.json["patchedpid"])
        openlucky = validate_string(request.json["openlucky"])
        rebootminutes = validate_string(request.json["rebootminutes"])
        deviceid = validate_string(request.json["deviceid"])
        websocketurl = validate_string(request.json["websocketurl"])
        catchPokemon = validate_string(request.json["catchPokemon"])
        catchRare = validate_string(request.json["catchRare"])
        launcherver = validate_string(request.json["launcherver"])
        rawpostdest = validate_string(request.json["rawpostdest"])
        lat = validate_string(request.json["lat"])
        lon = validate_string(request.json["lon"])
        overlay = validate_string(request.json["overlay"])
        RPL = validate_string(request.json["RPL"])
        memTot = validate_string(request.json["memTot"])
        memFree = validate_string(request.json["memFree"])
        memAv = validate_string(request.json["memAv"])
        memPogo = validate_string(request.json["memPogo"])
        memVM = validate_string(request.json["memVM"])
        cpuSys = validate_string(request.json["cpuSys"])
        cpuUser = validate_string(request.json["cpuUser"])
        cpuL5 = validate_string(request.json["cpuL5"])
        cpuL10 = validate_string(request.json["cpuL10"])
        cpuLavg = validate_string(request.json["cpuLavg"])
        cpuPogoPct = validate_string(request.json["cpuPogoPct"])
        cpuVmPct = validate_string(request.json["cpuVmPct"]) 
        numPogo = validate_string(request.json["numPogo"])
        whversion = validate_string(request.json["whversion"])
        wh_enabled = validate_string(request.json["wh_enabled"])
        vmc_reboot = validate_string(request.json["vmc_reboot"])
        vm_patcher_restart = validate_string(request.json["vm_patcher_restart"])
        vm_pogo_restart = validate_string(request.json["vm_pogo_restart"])
        vm_crash_dialog = validate_string(request.json["vm_crash_dialog"])
        vm_injection = validate_string(request.json["vm_injection"])
        vm_injectTimeout = validate_string(request.json["vm_injectTimeout"])
        vm_consent = validate_string(request.json["vm_consent"])
        vm_ws_stop_pogo = validate_string(request.json["vm_ws_stop_pogo"])
        vm_ws_start_pogo = validate_string(request.json["vm_ws_start_pogo"])
        vm_authStart = validate_string(request.json["vm_authStart"])
        vm_authSuccess = validate_string(request.json["vm_authSuccess"])
        vm_authFailed = validate_string(request.json["vm_authFailed"])
        vm_Gtoken = validate_string(request.json["vm_Gtoken"])
        vm_Ptoken = validate_string(request.json["vm_Ptoken"])
        vm_PtokenMaster = validate_string(request.json["vm_PtokenMaster"])
        vm_died = validate_string(request.json["vm_died"])



        insert_stmt1 = "\
            INSERT INTO ATVsummary \
                (origin, \
                timestamp, \
                arch, \
                productmodel, \
                vm_script, \
                55vmapper, \
                42vmapper, \
                pogo, \
                vmapper, \
                pogo_update, \
                vm_update, \
                temperature, \
                magisk, \
                magisk_modules, \
                MACw, \
                MACe, \
                ip, \
                ext_ip, \
                diskSysPct, \
                diskDataPct, \
                bootdelay, \
                gzip, \
                betamode, \
                selinux, \
                daemon, \
                authpassword, \
                authuser, \
                authid, \
                postdest, \
                fridastarted, \
                patchedpid, \
                openlucky, \
                rebootminutes, \
                deviceid, \
                websocketurl, \
                catchPokemon, \
                catchRare, \
                launcherver, \
                rawpostdest, \
                lat, \
                lon, \
                overlay, \
                whversion, \
                wh_enabled, \
                numPogo) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) \
            ON DUPLICATE KEY UPDATE \
                timestamp = VALUES(timestamp), \
                arch = VALUES(arch), \
                productmodel = VALUES(productmodel), \
                vm_script = VALUES(vm_script), \
                55vmapper = VALUES(55vmapper), \
                42vmapper = VALUES(42vmapper), \
                pogo = VALUES(pogo), \
                vmapper = VALUES(vmapper), \
                pogo_update = VALUES(pogo_update), \
                vm_update = VALUES(vm_update), \
                temperature = VALUES(temperature), \
                magisk = VALUES(magisk), \
                magisk_modules = VALUES(magisk_modules), \
                MACw = VALUES(MACw), \
                MACe = VALUES(MACe), \
                ip = VALUES(ip), \
                ext_ip = VALUES(ext_ip), \
                diskSysPct = VALUES(diskSysPct), \
                diskDataPct = VALUES(diskDataPct), \
                bootdelay = VALUES(bootdelay), \
                gzip = VALUES(gzip), \
                betamode = VALUES(betamode), \
                selinux = VALUES(selinux), \
                daemon = VALUES(daemon), \
                authpassword = VALUES(authpassword), \
                authuser = VALUES(authuser), \
                authid = VALUES(authid), \
                postdest = VALUES(postdest), \
                fridastarted = VALUES(fridastarted), \
                patchedpid = VALUES(patchedpid), \
                openlucky = VALUES(openlucky), \
                rebootminutes = VALUES(rebootminutes), \
                deviceid = VALUES(deviceid), \
                websocketurl = VALUES(websocketurl), \
                catchPokemon = VALUES(catchPokemon), \
                catchRare = VALUES(catchRare), \
                launcherver = VALUES(launcherver), \
                rawpostdest = VALUES(rawpostdest), \
                lat = VALUES(lat), \
                lon = VALUES(lon), \
                overlay = VALUES(overlay), \
                whversion = VALUES(whversion), \
                wh_enabled = VALUES(wh_enabled), \
                numPogo = VALUES(numPogo)"

        data1 = (str(origin), str(timestamp), str(arch), str(productmodel), str(vm_script), str(vmapper55), str(vmapper42), str(pogo), str(vmapper), str(pogo_update), str(vm_update), str(temperature), str(magisk), str(magisk_modules), str(macw), str(mace), str(ip), str(ext_ip), str(diskSysPct), str(diskDataPct), str(bootdelay), str(gzip), str(betamode), str(selinux), str(daemon), str(authpassword), str(authuser), str(authid), str(postdest), str(fridastarted), str(patchedpid), str(openlucky), str(rebootminutes), str(deviceid), str(websocketurl), str(catchPokemon), str(catchRare), str(launcherver), str(rawpostdest), str(lat), str(lon), str(overlay), str(whversion), str(wh_enabled), str(numPogo) )

        insert_stmt2 = (
            "INSERT INTO ATVstats (timestamp, RPL, origin, temperature, memTot, memFree, memAv, memPogo, memVM, cpuSys, cpuUser, cpuL5, cpuL10, cpuLavg, cpuPogoPct, cpuVmPct, diskSysPct, diskDataPct )"
            "VALUES ( %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s )"
        )        
        
        data2 = (str(timestamp), str(RPL), str(origin), str(temperature), str(memTot), str(memFree), str(memAv), str(memPogo), str(memVM), str(cpuSys), str(cpuUser), str(cpuL5), str(cpuL10), str(cpuLavg), str(cpuPogoPct), str(cpuVmPct), str(diskSysPct), str(diskDataPct) )

        insert_stmt3 = "\
            INSERT INTO ATVvmlog \
                (timestamp, \
                origin, \
                vmc_reboot, \
                vm_patcher_restart, \
                vm_pogo_restart, \
                vm_crash_dialog, \
                vm_injection, \
                vm_injectTimeout, \
                vm_consent, \
                vm_ws_stop_pogo, \
                vm_ws_start_pogo, \
                vm_authStart, \
                vm_authSuccess, \
                vm_authFailed, \
                vm_Gtoken, \
                vm_Ptoken, \
                vm_PtokenMaster, \
                vm_died) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) \
            ON DUPLICATE KEY UPDATE \
                timestamp = VALUES(timestamp), \
                origin = VALUES(origin), \
                vmc_reboot = VALUES(vmc_reboot), \
                vm_patcher_restart = VALUES(vm_patcher_restart), \
                vm_pogo_restart = VALUES(vm_pogo_restart), \
                vm_crash_dialog = VALUES(vm_crash_dialog), \
                vm_injection = VALUES(vm_injection), \
                vm_injectTimeout = VALUES(vm_injectTimeout), \
                vm_consent = VALUES(vm_consent), \
                vm_ws_stop_pogo = VALUES(vm_ws_stop_pogo), \
                vm_ws_start_pogo = VALUES(vm_ws_start_pogo), \
                vm_authStart = VALUES(vm_authStart), \
                vm_authSuccess = VALUES(vm_authSuccess), \
                vm_authFailed = VALUES(vm_authFailed), \
                vm_Gtoken = VALUES(vm_Gtoken), \
                vm_Ptoken = VALUES(vm_Ptoken), \
                vm_PtokenMaster = VALUES(vm_PtokenMaster), \
                vm_died = VALUES(vm_died)"

        data3 = ( str(timestamp), str(origin), str(vmc_reboot), str(vm_patcher_restart), str(vm_pogo_restart), str(vm_crash_dialog), str(vm_injection), str(vm_injectTimeout), str(vm_consent), str(vm_ws_stop_pogo), str(vm_ws_start_pogo), str(vm_authStart), str(vm_authSuccess), str(vm_authFailed), str(vm_Gtoken), str(vm_Ptoken), str(vm_PtokenMaster), str(vm_died) )


        try:
            connection_object = connection_pool.get_connection()
        
            # Get connection object from a pool
            if connection_object.is_connected():
                print("MySQL pool connection is open.")
                # Executing the SQL command
                cursor = connection_object.cursor()
                cursor.execute(insert_stmt1, data1)
                cursor.execute(insert_stmt2, data2)
                cursor.execute(insert_stmt3, data3)
                connection_object.commit()
                print("Data inserted")
                
        except Exception as e:
            # Rolling back in case of error
            connection_object.rollback()
            print(e)
            print("Data NOT inserted. rollbacked.")

        finally:
            # closing database connection.
            if connection_object.is_connected():
                cursor.close()
                connection_object.close()
                print("MySQL pool connection is closed.")

        return "Webhook received!"

# start scheduling
try:
    app.run(host=_host, port=_port)
	
except KeyboardInterrupt:
    print("Webhook receiver will be stopped")
    exit(0)
