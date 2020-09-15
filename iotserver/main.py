import paho.mqtt.client as paho
import time
import requests
broker="167.172.45.102"

port=1883
def on_publish(client,userdata,result):                 #create function for callback
    print("data published \n")
    pass
client1= paho.Client("control1")                           #create client object
client1.on_publish = on_publish                          #assign function to callback
client1.connect(broker,port)                            #establish connection


milli_sec = int(round(time.time() * 1000))
print(milli_sec)
data = "54:a2:74:e9:6e:c9;"+str(milli_sec)
ret= client1.publish("register/",data)
zone_name = ""
mobiletime = ""
arrivaltime = ""
endtime = ""
_data='log,zone='+zone_name+' mobiletime="'+mobiletime+'",arrivaltime="'+str(arrivaltime)+'",endtime="'+str(endtime)+'"'
x = requests.post("http://167.172.45.102:8086/write?db=logdb",data=_data) 