{
"category": {
"id": 0,
"name": "Miscellaneous"
},
"description": "Predictor for species from model/54366426fec7be06590007de",
"tags": [
"species"
],
"objective_field": "000004",
"name": "iris.csv",
"created": "2014-10-09T10:32:06.429000",
"input_fields": [
"000000",
"000001",
"000002",
"000003"
],
"model": {
"kind": "mtree",
"importance": [
[
"000002",
0.70194
],
[
"000003",
0.29094
],
[
"000001",
0.00712
]
],
"fields": {
"000004": {
"optype": "categorical",
"name": "species",
"datatype": "string",
"preferred": true,
"term_analysis": {
"enabled": true
},
"column_number": 4,
"order": 4
},
"000002": {
"optype": "numeric",
"name": "petal length",
"datatype": "double",
"preferred": true,
"column_number": 2,
"order": 2
},
"000003": {
"optype": "numeric",
"name": "petal width",
"datatype": "double",
"preferred": true,
"column_number": 3,
"order": 3
},
"000000": {
"optype": "numeric",
"name": "sepal length",
"datatype": "double",
"preferred": true,
"column_number": 0,
"order": 0
},
"000001": {
"optype": "numeric",
"name": "sepal width",
"datatype": "double",
"preferred": true,
"column_number": 1,
"order": 1
}
},
"node_threshold": 512,
"model_fields": {
"000004": {
"optype": "categorical",
"name": "species",
"datatype": "string",
"term_analysis": {
"enabled": true
},
"preferred": true,
"column_number": 4
},
"000002": {
"datatype": "double",
"optype": "numeric",
"name": "petal length",
"preferred": true,
"column_number": 2
},
"000003": {
"datatype": "double",
"optype": "numeric",
"name": "petal width",
"preferred": true,
"column_number": 3
},
"000001": {
"datatype": "double",
"optype": "numeric",
"name": "sepal width",
"preferred": true,
"column_number": 1
}
},
"missing_tokens": [
"",
"NaN",
"NULL",
"N/A",
"null",
"-",
"#REF!",
"#VALUE!",
"?",
"#NULL!",
"#NUM!",
"#DIV/0",
"n/a",
"#NAME?",
"NIL",
"nil",
"na",
"#N/A",
"NA"
],
"root": {
"count": 150,
"confidence": 0.26289,
"predicate": true,
"id": 0,
"objective_summary": {
"categories": [
[
"Iris-setosa",
50
],
[
"Iris-versicolor",
50
],
[
"Iris-virginica",
50
]
]
},
"output": "Iris-setosa",
"children": [
{
"count": 100,
"confidence": 0.40383,
"predicate": {
"operator": ">",
"field": "000002",
"value": 2.45
},
"id": 1,
"objective_summary": {
"categories": [
[
"Iris-versicolor",
50
],
[
"Iris-virginica",
50
]
]
},
"output": "Iris-versicolor",
"children": [
{
"count": 46,
"confidence": 0.88664,
"predicate": {
"operator": ">",
"field": "000003",
"value": 1.75
},
"id": 2,
"objective_summary": {
"categories": [
[
"Iris-virginica",
45
],
[
"Iris-versicolor",
1
]
]
},
"output": "Iris-virginica",
"children": [
{
"count": 43,
"confidence": 0.91799,
"predicate": {
"operator": ">",
"field": "000002",
"value": 4.85
},
"objective_summary": {
"categories": [
[
"Iris-virginica",
43
]
]
},
"output": "Iris-virginica",
"id": 3
},
{
"count": 3,
"confidence": 0.20765,
"predicate": {
"operator": "<=",
"field": "000002",
"value": 4.85
},
"id": 4,
"objective_summary": {
"categories": [
[
"Iris-virginica",
2
],
[
"Iris-versicolor",
1
]
]
},
"output": "Iris-virginica",
"children": [
{
"count": 1,
"confidence": 0.20654,
"predicate": {
"operator": ">",
"field": "000001",
"value": 3.1
},
"objective_summary": {
"categories": [
[
"Iris-versicolor",
1
]
]
},
"output": "Iris-versicolor",
"id": 5
},
{
"count": 2,
"confidence": 0.34237,
"predicate": {
"operator": "<=",
"field": "000001",
"value": 3.1
},
"objective_summary": {
"categories": [
[
"Iris-virginica",
2
]
]
},
"output": "Iris-virginica",
"id": 6
}
]
}
]
},
{
"count": 54,
"confidence": 0.8009,
"predicate": {
"operator": "<=",
"field": "000003",
"value": 1.75
},
"id": 7,
"objective_summary": {
"categories": [
[
"Iris-versicolor",
49
],
[
"Iris-virginica",
5
]
]
},
"output": "Iris-versicolor",
"children": [
{
"count": 6,
"confidence": 0.29999,
"predicate": {
"operator": ">",
"field": "000002",
"value": 4.95
},
"id": 8,
"objective_summary": {
"categories": [
[
"Iris-virginica",
4
],
[
"Iris-versicolor",
2
]
]
},
"output": "Iris-virginica",
"children": [
{
"count": 3,
"confidence": 0.20765,
"predicate": {
"operator": ">",
"field": "000003",
"value": 1.55
},
"id": 9,
"objective_summary": {
"categories": [
[
"Iris-versicolor",
2
],
[
"Iris-virginica",
1
]
]
},
"output": "Iris-versicolor",
"children": [
{
"count": 1,
"confidence": 0.20654,
"predicate": {
"operator": ">",
"field": "000002",
"value": 5.45
},
"objective_summary": {
"categories": [
[
"Iris-virginica",
1
]
]
},
"output": "Iris-virginica",
"id": 10
},
{
"count": 2,
"confidence": 0.34237,
"predicate": {
"operator": "<=",
"field": "000002",
"value": 5.45
},
"objective_summary": {
"categories": [
[
"Iris-versicolor",
2
]
]
},
"output": "Iris-versicolor",
"id": 11
}
]
},
{
"count": 3,
"confidence": 0.43849,
"predicate": {
"operator": "<=",
"field": "000003",
"value": 1.55
},
"objective_summary": {
"categories": [
[
"Iris-virginica",
3
]
]
},
"output": "Iris-virginica",
"id": 12
}
]
},
{
"count": 48,
"confidence": 0.89101,
"predicate": {
"operator": "<=",
"field": "000002",
"value": 4.95
},
"id": 13,
"objective_summary": {
"categories": [
[
"Iris-versicolor",
47
],
[
"Iris-virginica",
1
]
]
},
"output": "Iris-versicolor",
"children": [
{
"count": 1,
"confidence": 0.20654,
"predicate": {
"operator": ">",
"field": "000003",
"value": 1.65
},
"objective_summary": {
"categories": [
[
"Iris-virginica",
1
]
]
},
"output": "Iris-virginica",
"id": 14
},
{
"count": 47,
"confidence": 0.92444,
"predicate": {
"operator": "<=",
"field": "000003",
"value": 1.65
},
"objective_summary": {
"categories": [
[
"Iris-versicolor",
47
]
]
},
"output": "Iris-versicolor",
"id": 15
}
]
}
]
}
]
},
{
"count": 50,
"confidence": 0.92865,
"predicate": {
"operator": "<=",
"field": "000002",
"value": 2.45
},
"objective_summary": {
"categories": [
[
"Iris-setosa",
50
]
]
},
"output": "Iris-setosa",
"id": 16
}
]
},
"distribution": {
"training": {
"categories": [
[
"Iris-setosa",
50
],
[
"Iris-versicolor",
50
],
[
"Iris-virginica",
50
]
]
},
"predictions": {
"categories": [
[
"Iris-setosa",
50
],
[
"Iris-versicolor",
50
],
[
"Iris-virginica",
50
]
]
}
},
"depth_threshold": 512
}
}