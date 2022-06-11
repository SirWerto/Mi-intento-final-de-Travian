import pandas as pd
import pickle
import datetime


def process_row(row):
    date = datetime.date.fromisoformat(row["date"])
    weekday = date.weekday()
    return {
        "do": row["distance_to_origin"],
        "weekend": weekday in [5, 6],
        "weekday": weekday,
        "dow": row["dow"],
        "n_villages": row["n_villages"],
        "total_population": row["total_population"],
        "player_id": row["player_id"]
    }


def process_train_row(train_row):
    (xd, y) = train_row
    xdict = process_row(xd)
    xdict["y"] = y
    return xdict


class medusa_model_n:

    def __init__(self, model_name):
        self.pred_model = pickle.load(open(model_name, "rb"))

    def predict(self, data):
        df = pd.DataFrame([process_row(x) for x in data])
        pid = list(df["player_id"].values)
        X = df.drop(columns=["player_id"]).values
        # predictions = self.pred_model.predict(X)
        predictions = ["Inactive" if pred is True else "Active" for pred in self.pred_model.predict(X)]
        pack = zip(["player_n"]*len(predictions), pid, list(predictions))
        return list(pack)
