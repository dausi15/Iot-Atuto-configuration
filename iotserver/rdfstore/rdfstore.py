from rdflib import Graph, Namespace

class Rdfdatastore():
    
    def __init__(self, project_name, building_name):
        print("Initializing store")
        RDF        = Namespace('http://www.w3.org/1999/02/22-rdf-syntax-ns#')
        RDFS       = Namespace('http://www.w3.org/2000/01/rdf-schema#')
        OWL        = Namespace('http://www.w3.org/2002/07/owl#')
        BRICK      = Namespace('http://buildsys.org/ontologies/Brick#')
        BRICKFRAME = Namespace('http://buildsys.org/ontologies/BrickFrame#')
        BRICKTAG   = Namespace('http://buildsys.org/ontologies/BrickTag#')
        BD          = Namespace('https://brickschema.org/schema/1.0.1/BrickData#')
        BDS         = Namespace('https://brickschema.org/schema/1.0.1/BrickDataStatic#')
        BDSMAP     = Namespace('https://brickschema.org/schema/1.0.1/BrickDataSmap#')
        self.N = Namespace('http://buildsys.org/ontologies/%s/' % project_name)
        self.store = Graph()
        self.BUILDING = self.N['buildings/%s#' % building_name]
        self.store.parse('Brick.ttl', format='turtle')
        self.store.parse('BrickFrame.ttl', format='turtle')
        self.store.parse('BrickTag.ttl', format='turtle')
        self.store.parse('brick-data.ttl', format='turtle')
        self.store.bind('rdf'  , RDF)
        self.store.bind('rdfs' , RDFS)
        self.store.bind('owl'  , OWL)
        self.store.bind('brick', BRICK)
        self.store.bind('bf'   , BRICKFRAME)
        self.store.bind('btag' , BRICKTAG)
        #self.store.bind('n'    , self.N)
        self.store.bind('bd'   , BD)
        self.store.bind('bds'  , BDS)
        self.store.bind('ou44', self.get_building_namespace())

        self.add_triple_to_store([(self.get_building_namespace(), RDF.type, BRICK['Building'])])

        print(self.N)
        

    def saveStore(self):
        print("Saving store")
        dest = "building-ou44.ttl"                                                                 #without hoddb
        self.store.serialize(destination=dest, format='ttl')

    def get_building_namespace(self):
        return self.BUILDING

    def add_triple_to_store(self, triples):
        for triple in triples:
            if self.store.__contains__(triple):
                #print(str(triple) + " exists in model and wont be added")
                pass
            else:
                self.store.add(triple)

