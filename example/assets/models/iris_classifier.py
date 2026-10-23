"""
On-Device Iris Flower Classification Model
Runs locally without network or external APIs.
"""

def predict(features):
    # features: [sepal_length, sepal_width, petal_length, petal_width]
    if isinstance(features, dict) and "features" in features:
        features = features["features"]

    sepal_length = float(features[0]) if len(features) > 0 else 5.1
    sepal_width = float(features[1]) if len(features) > 1 else 3.5
    petal_length = float(features[2]) if len(features) > 2 else 1.4
    petal_width = float(features[3]) if len(features) > 3 else 0.2

    print(f"[Python Model] Features received: {features}")

    # Decision boundary simulation
    if petal_length < 2.45:
        label = "setosa"
        probs = [0.985, 0.012, 0.003]
    elif petal_width < 1.75:
        label = "versicolor"
        probs = [0.025, 0.920, 0.055]
    else:
        label = "virginica"
        probs = [0.010, 0.075, 0.915]

    return {
        "label": label,
        "class_index": 0 if label == "setosa" else (1 if label == "versicolor" else 2),
        "confidence": max(probs),
        "probabilities": probs,
        "classes": ["setosa", "versicolor", "virginica"],
    }
