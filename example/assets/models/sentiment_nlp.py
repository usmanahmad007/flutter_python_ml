"""
On-Device Text Sentiment & Feature Extraction Model
Evaluates polarity score from input text tokens locally.
"""

def predict(arguments):
    text = ""
    if isinstance(arguments, dict) and "text" in arguments:
        text = str(arguments["text"])
    elif isinstance(arguments, str):
        text = arguments
    elif isinstance(arguments, list) and len(arguments) > 0:
        text = str(arguments[0])

    print(f"[Python NLP] Analyzing text: '{text}'")

    lower = text.lower()
    pos_words = ["great", "amazing", "love", "good", "fast", "best", "excellent", "super", "clean"]
    neg_words = ["bad", "terrible", "slow", "hate", "poor", "worst", "broken", "bug", "crash"]

    pos_score = sum(1 for w in pos_words if w in lower)
    neg_score = sum(1 for w in neg_words if w in lower)

    net_score = pos_score - neg_score
    is_pos = net_score >= 0

    confidence = min(0.99, 0.70 + (abs(net_score) * 0.08))

    return {
        "label": "POSITIVE" if is_pos else "NEGATIVE",
        "confidence": confidence,
        "positive_hits": pos_score,
        "negative_hits": neg_score,
        "token_count": len(text.split()),
    }
