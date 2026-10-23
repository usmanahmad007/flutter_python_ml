"""
On-Device Real Estate Price Prediction Model
Linear/Ridge Regression equation running locally on-device.
"""

def predict(features):
    if isinstance(features, list):
        sqft = float(features[0]) if len(features) > 0 else 1800.0
        beds = float(features[1]) if len(features) > 1 else 3.0
        baths = float(features[2]) if len(features) > 2 else 2.0
    elif isinstance(features, dict):
        sqft = float(features.get("sqft", 1800.0))
        beds = float(features.get("beds", 3.0))
        baths = float(features.get("baths", 2.0))
    else:
        sqft, beds, baths = 1800.0, 3.0, 2.0

    print(f"[Python Model] Evaluating house: {sqft} sqft, {beds} beds, {baths} baths")

    base = 135000.0
    price = base + (sqft * 175.50) + (beds * 24000.0) + (baths * 16500.0)

    return {
        "predicted_price": round(price, 2),
        "currency": "USD",
        "sqft_valuation": round(sqft * 175.50, 2),
        "rooms_valuation": round((beds * 24000.0) + (baths * 16500.0), 2),
    }
