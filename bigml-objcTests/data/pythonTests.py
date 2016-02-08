#!/usr/bin/env python

from bigml.api import BigML
from bigml.model import Model
from bigml.ensemble import Ensemble
from bigml.anomaly import Anomaly
from bigml.cluster import Cluster
from bigml.logistic import LogisticRegression

api = BigML(dev_mode=False)

#clusterJson = api.get_cluster('cluster/5644d1ad636e1c79b00037b9')
#cluster = Cluster('cluster/5644d1ad636e1c79b00037b9', api=api)
#prediction = cluster.centroid({'petal length': 4.07, 'sepal width': 3.15, 'petal width': 1.51, 'sepal length' : 4.0, 'species' : 'Iris-setosa'}, by_name=True)

#cluster = Cluster('cluster/565f088fce165e0a1401783c', api=api)
#prediction = cluster.centroid({'Team': "Atlanta Braves", 'Salary': 30000, 'Position': "Pitcher"}, by_name=True)
#prediction = cluster.centroid({'Team': "Atlanta Braves", 'Salary': 30000000000, 'Position': "Shortstop"}, by_name=True)

# api.pprint(prediction)

# prediction = cluster.centroid({'petal length': 2.07, 'sepal width': 4.8, 'petal width': 2.51, 'sepal length' : 8.2, 'species' : 'iris-setosa'}, by_name=True)


# model = api.get_model('model/563a1c7a3cd25747430023ce')
# prediction = api.create_prediction(model, {'petal length': 4.07, 'sepal width': 3.15, 'petal width': 1.51})

# local_model = Model('model/56430eb8636e1c79b0001f90', api=api)
# prediction = local_model.predict({'petal length': 0.96, 'sepal width': 4.1, 'petal width': 2.52}, 2, add_confidence=True, multiple=3)

#local_model = Ensemble('ensemble/563219b8636e1c5eca006d38', api=api)
# local_model = Ensemble('ensemble/564a081bc6c19b6cf3011c60', api=api)
#prediction = local_model.predict({'petal length': 0.96, 'sepal width': 2.25, 'petal width': 1.51, 'sepal length': 6.02}, method=2, add_confidence=True)

#local_model = Ensemble('ensemble/5666fb621d55051209009f0f', api=api)
#prediction = local_model.predict({'Salary': 18000000, 'Team' : 'Atlanta Braves'}, method=0, add_confidence=True)
#local_model = Ensemble('ensemble/566954af1d5505120900bf69', api=api)
#prediction = local_model.predict({'Price' : 5.8, 'Grape' : 'Pinot Grigio', 'Rating' : 89, 'Country' : 'Italy'}, method=1, add_confidence=True, add_distribution=True)

# local_ensemble = Ensemble('ensemble/564623d4636e1c79b00051f7', api=api)
# prediction = local_ensemble.predict({'Price' : 5.8, 'Grape' : 'Pinot Grigio', 'Country' : 'Italy', 'Rating' : 92}, True)

# local_anomaly = Anomaly('anomaly/564c5a76636e1c3d52000007', api=api)
# prediction = local_anomaly.anomaly_score({'petal length': 4.07, 'sepal width': 3.15, 'petal width': 1.51, 'sepal length': 6.02, 'species': 'Iris-setosa'}, True)
# prediction = local_anomaly.anomaly_score({'petal length': 0.96, 'sepal width': 4.1, 'petal width': 2.51, 'sepal length': 6.02, 'species': 'Iris-setosa'}, True)
# prediction = local_anomaly.anomaly_score({'petal length': 0.96, 'sepal width': 4.1, 'petal width': 2.51}, True)

logistic_regression = LogisticRegression(
    'logisticregression/5697c1179ed2334090003217')
prediction = logistic_regression.predict({"petal length": 4.07, "petal width": 14.07,
                             "sepal length": 6.02, "sepal width": 3.15})

api.pprint(prediction)
