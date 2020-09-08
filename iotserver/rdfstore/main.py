from rdfstore import Rdfdatastore

rdfstore = Rdfdatastore("iotautoconf", "ou44")


print(rdfstore)

print(rdfstore.get_building_namespace())
rdfstore.saveStore()



